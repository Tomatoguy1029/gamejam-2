extends CanvasLayer

## 動画アイコン（白塗りSVG）。modulate でゴースト色に染める。
const MOVIE_ICON: Texture2D = preload("res://src/assets/movieplay.svg")
const DASHED_BOX := preload("res://src/scripts/ui/dashed_box.gd")

## 動画アイコン／空きスロットのサイズ。HUD ノードのインスペクタで調整できる。
@export var icon_size: Vector2 = Vector2(140, 104)
@export var num_font_size: int = 40
@export var del_font_size: int = 32

@onready var _play_ended_panel: Control = $PlayEndedPanel
@onready var _clear_panel: Control = $ClearPanel
@onready var _idle_panel: Control = $IdlePanel
@onready var _camera_frame: Control = $CameraFrame
@onready var _ghost_icons: HBoxContainer = $PlayEndedPanel/VBox/GhostIcons
@onready var _yes_button: Button = $PlayEndedPanel/VBox/YesNo/SaveButton

func _ready() -> void:
	$PlayEndedPanel/VBox/YesNo/SaveButton.pressed.connect(_on_save_pressed)
	$PlayEndedPanel/VBox/YesNo/DiscardButton.pressed.connect(_on_discard_pressed)
	$PlayEndedPanel/VBox/ReturnTitleButton.pressed.connect(GameManager.request_return_to_title)
	$ClearPanel/VBox/NextStageButton.pressed.connect(GameManager.request_next_stage)
	$ClearPanel/VBox/TitleButton.pressed.connect(GameManager.request_return_to_title)

	GameManager.state_changed.connect(_on_state_changed)
	GameManager.ghost_saved.connect(_refresh_ghost_icons)
	GameManager.over_limit.connect(_refresh_ghost_icons)
	GameManager.ghost_discarded.connect(_refresh_ghost_icons)
	GameManager.room_retried.connect(_refresh_ghost_icons)
	GameManager.return_to_title_requested.connect(_refresh_ghost_icons)

	_update_panels(GameManager.GameState.MAIN_MENU)

func _on_state_changed(state: int) -> void:
	_update_panels(state as GameManager.GameState)

func _update_panels(state: GameManager.GameState) -> void:
	_idle_panel.visible = state == GameManager.GameState.IDLE
	_play_ended_panel.visible = (
		state == GameManager.GameState.PLAY_ENDED
		or state == GameManager.GameState.OVER_LIMIT
	)
	_clear_panel.visible = state == GameManager.GameState.CLEAR
	_camera_frame.visible = state == GameManager.GameState.PLAYING
	_update_yes_button()
	# パネル表示時にスロット（録画0でも点線枠）を必ず作り直す
	if _play_ended_panel.visible:
		_refresh_ghost_icons()

func _update_yes_button() -> void:
	_yes_button.disabled = LoopManager.is_at_limit

## 常に「録画可能数（max_ghosts）」ぶんのスロットを並べる。
func _refresh_ghost_icons() -> void:
	for child in _ghost_icons.get_children():
		child.queue_free()
	var maxn: int = maxi(0, LoopManager.max_ghosts)
	var saved: int = mini(LoopManager.ghost_count, maxn)
	for i in maxn:
		if i < saved:
			var ghost: GhostData = LoopManager.ghosts[i]
			_ghost_icons.add_child(_make_icon_cell(i, ghost.color))
		else:
			_ghost_icons.add_child(_make_empty_cell())

## 空き録画スロット（点線の角丸四角）のセル。
func _make_empty_cell() -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 4)

	var box: Control = DASHED_BOX.new()
	box.custom_minimum_size = icon_size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(box)

	# 番号ラベルと高さを揃えるための空ラベル
	var pad := Label.new()
	pad.add_theme_font_size_override("font_size", num_font_size)
	cell.add_child(pad)

	return cell

## 1ゴースト分のセル（動画アイコン＋右上×、下に番号）を作る。
func _make_icon_cell(index: int, color: Color) -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 4)

	var holder := Control.new()
	holder.custom_minimum_size = icon_size

	var tex := TextureRect.new()
	tex.texture = MOVIE_ICON
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.modulate = color
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(tex)

	# 右上の×（削除）ボタン
	var del := Button.new()
	del.text = "×"
	del.add_theme_font_size_override("font_size", del_font_size)
	del.anchor_left = 1.0
	del.anchor_right = 1.0
	del.offset_left = -36.0
	del.offset_top = -12.0
	del.offset_right = 12.0
	del.offset_bottom = 36.0
	var idx := index
	del.pressed.connect(func() -> void: _on_delete_ghost(idx))
	holder.add_child(del)

	cell.add_child(holder)

	# 下の番号
	var num := Label.new()
	num.text = str(index + 1)
	num.add_theme_font_size_override("font_size", num_font_size)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(num)

	return cell

func _on_save_pressed() -> void:
	# 保存処理（枠判定・演出・状態遷移）は LoopManager.save_recording() に集約
	LoopManager.save_recording(RecordingManager.build_ghost_data())
	_refresh_ghost_icons()

func _on_discard_pressed() -> void:
	GameManager.discard_ghost()

func _on_delete_ghost(index: int) -> void:
	# GameState は変えない。削除後もそのまま Yes/No を選べるようにする。
	LoopManager.remove_ghost(index)
	_refresh_ghost_icons()
	_update_yes_button()  # 空きができたら Yes を黄緑に戻す
