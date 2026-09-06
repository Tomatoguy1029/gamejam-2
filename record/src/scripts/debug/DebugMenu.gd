## 実行中に開くデバッグメニュー。エディタから起動したときだけ有効。
##
## 項目は _build_items() に1行ずつ足す。UI の組み立ては _add_* ヘルパーに任せ、
## 項目ごとにレイアウトを書かないこと。項目が増えることを前提にした作りにしてある。
##
## 値は getter / setter の Callable で受け取る。メニューが値を自前で保持すると
## ゲーム側の実際の値とずれるため、参照元を毎回読みに行く。これにより
## 他の経路（ステージ切り替えなど）で値が変わっても表示が自動的に追随する。
##
## 項目のロジックはこのファイルに閉じ込め、既存クラスにデバッグ用のメソッドや
## フラグを生やさないこと。
extends CanvasLayer

## メニューの開閉ショートカット。インスペクタから割り当てを変えられる。
## 既定は Esc。ファンクションキー（F3 など）は OS 側のショートカットに
## 取られることがあるため既定にしない。
##
## project.godot の入力マップは使わない。製品側の設定にデバッグ用アクションの
## 痕跡を残さないため。
@export var toggle_menu_shortcut: Shortcut

# ── 見た目 ────────────────────────────────────────────────────────────────────
# 画面は 1920x1080 なので、既定のフォントサイズだとゲーム側の HUD に比べて
# 極端に小さく見える。ここで明示的に大きめに揃える。
const PANEL_WIDTH: float = 780.0
## 内容がこれを超えたらスクロールに切り替える高さ
const MAX_CONTENT_HEIGHT: float = 860.0
const LABEL_COLUMN_WIDTH: float = 260.0

const SECTION_FONT_SIZE: int = 34
const LABEL_FONT_SIZE: int = 24
const BUTTON_FONT_SIZE: int = 22

## 操作できる項目の見出し
const COLOR_SECTION: Color = Color(0.45, 0.78, 1.0)
## 表示だけの項目の見出し
const COLOR_SECTION_READONLY: Color = Color(0.62, 0.66, 0.72)
const COLOR_LABEL: Color = Color(0.80, 0.83, 0.87)
## 表示だけの値。操作できるものと区別できるよう色を変える。
const COLOR_INFO_VALUE: Color = Color(1.0, 0.85, 0.45)

@onready var _panel: Control = $Panel
@onready var _scroll: ScrollContainer = $Panel/Scroll
@onready var _items: VBoxContainer = $Panel/Scroll/Items

## _add_info で登録した [Label, getter] の組。開くたびに再評価する。
var _infos: Array = []

## ステージ一覧のボタン位置 → 実際のステージ番号
var _stage_indices: Array[int] = []

## [Shortcut, 実行する処理] の組。_build_shortcuts() に1行足せば増える。
var _shortcuts: Array = []

var is_open: bool:
	get: return _panel.visible

## エディタから実行しているときだけデバッグ機能を有効にする。
static func is_available() -> bool:
	return OS.has_feature("editor")

func _ready() -> void:
	# 製品ビルドではノードごと消す（保険。Main 側でも同じ判定をしている）
	if not is_available():
		queue_free()
		return
	_panel.visible = false
	_build_items()
	refresh_shortcuts()
	_fit_panel()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	for pair in _shortcuts:
		var shortcut: Shortcut = pair[0]
		if not shortcut.matches_event(event):
			continue
		(pair[1] as Callable).call()
		get_viewport().set_input_as_handled()
		return

func toggle() -> void:
	# 巻き戻し演出などが入力をロックしている間は開かない。
	# 開いてしまうと、閉じたときに演出側のロックまで解除してしまう。
	if not is_open and GameManager.input_locked:
		return
	set_open(not is_open)

func set_open(open: bool) -> void:
	_panel.visible = open
	# 開いている間はゲーム操作を止める（既存の入力ロックを流用）
	GameManager.input_locked = open
	if open:
		_refresh_infos()

# ── ショートカット ────────────────────────────────────────────────────────────

## 割り当てを変えたあとに呼ぶと、その場で反映される。
func refresh_shortcuts() -> void:
	_shortcuts.clear()
	_build_shortcuts()

## ここに1行足すだけでショートカットが増える。
func _build_shortcuts() -> void:
	_bind(toggle_menu_shortcut, toggle)

## Shortcut と処理を結びつける。未割り当て（null または空）なら何もしない。
func _bind(shortcut: Shortcut, action: Callable) -> void:
	if shortcut != null and shortcut.has_valid_event():
		_shortcuts.append([shortcut, action])

# ── 項目の定義 ────────────────────────────────────────────────────────────────
## ここに1行足すだけで項目が増える。
func _build_items() -> void:
	_add_section("ステージ")
	_stage_indices = _scan_levels()
	var labels := PackedStringArray()
	for index in _stage_indices:
		labels.append("Stage %d" % index)
	_add_list("移動", labels, _goto_stage)

	_add_section("ループ")
	_add_int("ゴースト数", func() -> int: return LoopManager.max_ghosts,
			_set_max_ghosts, 0, 8)

	_add_section("状態", true)
	_add_info("GameState", func() -> String: return _state_name())
	_add_info("現在のステージ", _current_stage_text)
	_add_info("保存済みゴースト", func() -> String:
		return "%d / %d" % [LoopManager.ghost_count, LoopManager.max_ghosts])

# ── 登録 API ──────────────────────────────────────────────────────────────────

## 見出し。項目のグループ分けに使う。
## readonly を true にすると「表示のみ」と明示し、操作できる節と色で区別する。
func _add_section(title: String, readonly: bool = false) -> void:
	if _items.get_child_count() > 0:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		_items.add_child(spacer)
		_items.add_child(HSeparator.new())
	var label := Label.new()
	label.text = title + ("　（表示のみ）" if readonly else "")
	label.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	label.add_theme_color_override("font_color",
		COLOR_SECTION_READONLY if readonly else COLOR_SECTION)
	_items.add_child(label)

## ボタン1つ。単発の操作に使う。
func _add_action(label: String, on_press: Callable) -> Control:
	var button := _make_button(label)
	button.pressed.connect(on_press)
	return _add_row(_row(label, button))

## − / 数値 / ＋ の整数スピナー。
func _add_int(label: String, getter: Callable, setter: Callable,
		min_value: int, max_value: int) -> Control:
	var value := Label.new()
	value.custom_minimum_size = Vector2(64, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	value.text = str(getter.call())

	var apply := func(delta: int) -> void:
		var next: int = clampi(int(getter.call()) + delta, min_value, max_value)
		setter.call(next)
		value.text = str(getter.call())  # setter が拒否した場合も実値を映す

	var minus := _make_button("−")
	minus.pressed.connect(func() -> void: apply.call(-1))
	var plus := _make_button("＋")
	plus.pressed.connect(func() -> void: apply.call(1))

	return _add_row(_row(label, minus, value, plus))

## チェックボックス。ON/OFF のフラグに使う。
func _add_bool(label: String, getter: Callable, setter: Callable) -> Control:
	var check := CheckBox.new()
	check.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	check.button_pressed = bool(getter.call())
	check.toggled.connect(func(on: bool) -> void:
		setter.call(on)
		check.button_pressed = bool(getter.call())
	)
	return _add_row(_row(label, check))

## ボタンの並び。ステージ一覧のような選択肢に使う。
func _add_list(label: String, labels: PackedStringArray, on_select: Callable) -> Control:
	# HFlowContainer にして、ステージが増えても横に見切れず折り返すようにする
	var box := HFlowContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in labels.size():
		var button := _make_button(labels[i])
		var index := i
		button.pressed.connect(func() -> void: on_select.call(index))
		box.add_child(button)
	return _add_row(_row(label, box))

## 読み取り専用の表示。メニューを開くたびに getter を評価し直す。
func _add_info(label: String, getter: Callable) -> Control:
	var value := Label.new()
	value.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	value.add_theme_color_override("font_color", COLOR_INFO_VALUE)
	value.text = str(getter.call())
	_infos.append([value, getter])
	return _add_row(_row(label, value))

# ── 項目の中身 ────────────────────────────────────────────────────────────────

## scenes/levels/ を走査してステージ番号を集める。StageSelect と同じ方式なので、
## LevelNNN.tscn を置けばデバッグメニューにも自動で並ぶ。
func _scan_levels() -> Array[int]:
	var out: Array[int] = []
	var dir := DirAccess.open("res://scenes/levels/")
	if dir == null:
		return out
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("Level") and file_name.ends_with(".tscn"):
			var num: String = file_name.trim_prefix("Level").trim_suffix(".tscn")
			if num.is_valid_int():
				out.append(num.to_int())
		file_name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out

## 使えるゴーストの数を変える。値を書き換えただけでは HUD やバッテリーに
## 再描画の契機が無いので、現在の状態を入れ直して購読者に更新させる。
##
## IDLE 中はこれでアクターの再配置とワールドリセットも走るが、盤面が初期状態に
## 戻るだけで実害はない（デバッグ用途としてはむしろ都合がよい）。
func _set_max_ghosts(value: int) -> void:
	LoopManager.max_ghosts = value
	GameManager.change_state(GameManager.current_state)

## 読み込まれているステージ名。Main の下にぶら下がっている Level を探す。
func _current_stage_text() -> String:
	var parent: Node = get_parent()
	if parent != null:
		for child in parent.get_children():
			if child is Level:
				return child.name
	return "(なし)"

## ステージを切り替える。実ゲームのステージ選択と同じ経路（StageSelect の
## stage_selected シグナル）を通すため、Main にデバッグ用の入口を足さずに済む。
func _goto_stage(position: int) -> void:
	if position < 0 or position >= _stage_indices.size():
		return
	var select: Node = get_parent().get_node_or_null("StageSelect")
	if select == null or not select.has_signal("stage_selected"):
		push_warning("デバッグメニュー: StageSelect が見つからないので移動できない")
		return
	set_open(false)  # 先に閉じて入力ロックを外してから移動する
	select.stage_selected.emit(_stage_indices[position])

# ── 内部 ──────────────────────────────────────────────────────────────────────

## 作った行をメニューに並べ、そのまま返す。
## 返り値は呼び出し側での微調整とテストのために使う。
func _add_row(row: Control) -> Control:
	_items.add_child(row)
	return row

## 「ラベル ＋ 任意個のコントロール」の 1 行を作る。
func _row(label: String, control_a: Control, control_b: Control = null,
		control_c: Control = null) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_label := Label.new()
	name_label.text = label
	name_label.custom_minimum_size = Vector2(LABEL_COLUMN_WIDTH, 0)
	name_label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	name_label.add_theme_color_override("font_color", COLOR_LABEL)
	row.add_child(name_label)

	for control in [control_a, control_b, control_c]:
		if control != null:
			row.add_child(control)
	return row

## 見た目を揃えたボタンを作る。
func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	button.custom_minimum_size = Vector2(0, 40)
	return button

## 内容の高さに合わせてパネルを縮める。項目が少ないうちに画面の左半分が
## 巨大な空の板で覆われないようにし、増えたらスクロールへ切り替える。
func _fit_panel() -> void:
	await get_tree().process_frame  # レイアウト確定を待つ
	_panel.custom_minimum_size.x = PANEL_WIDTH
	var content_height: float = _items.get_combined_minimum_size().y
	_scroll.custom_minimum_size = Vector2(0.0, minf(content_height, MAX_CONTENT_HEIGHT))
	_panel.reset_size()

func _refresh_infos() -> void:
	for pair in _infos:
		var label: Label = pair[0]
		var getter: Callable = pair[1]
		label.text = str(getter.call())

func _state_name() -> String:
	var names := ["MAIN_MENU", "IDLE", "PLAYING", "PLAY_ENDED", "OVER_LIMIT", "CLEAR", "ROOM_RETRY"]
	var i: int = int(GameManager.current_state)
	return names[i] if i >= 0 and i < names.size() else str(i)
