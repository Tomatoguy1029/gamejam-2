extends CanvasLayer

const GHOST_ROW_COLOR_SIZE := Vector2(80, 80)
const GHOST_ROW_FONT_SIZE := 55
const GHOST_ROW_BTN_FONT_SIZE := 50

@onready var _timer_label: Label = $MarginContainer/VBoxContainer/TopRow/TimerLabel
@onready var _ghost_list: VBoxContainer = $MarginContainer/VBoxContainer/GhostList
@onready var _play_ended_panel: Control = $PlayEndedPanel
@onready var _clear_panel: Control = $ClearPanel
@onready var _idle_panel: Control = $IdlePanel
enum SaveEffect { WHITEOUT, NOISE, TEXT_SHAKE }
@export var save_effect: SaveEffect = SaveEffect.WHITEOUT

var _flash_rect: ColorRect
var _noise_rect: ColorRect
var _saved_label: Label

func _ready() -> void:
	$PlayEndedPanel/VBox/SaveButton.pressed.connect(_on_save_pressed)
	$PlayEndedPanel/VBox/DiscardButton.pressed.connect(_on_discard_pressed)
	$PlayEndedPanel/VBox/ReturnTitleButton.pressed.connect(GameManager.request_return_to_title)
	$ClearPanel/VBox/NextStageButton.pressed.connect(GameManager.request_next_stage)
	$ClearPanel/VBox/TitleButton.pressed.connect(GameManager.request_return_to_title)

	GameManager.state_changed.connect(_on_state_changed)
	GameManager.ghost_saved.connect(_refresh_ghost_list)
	GameManager.ghost_discarded.connect(_refresh_ghost_list)
	GameManager.room_retried.connect(_refresh_ghost_list)
	GameManager.return_to_title_requested.connect(_refresh_ghost_list)

	_setup_save_feedback()
	GameManager.ghost_saved.connect(_play_save_feedback)
	_update_panels(GameManager.GameState.MAIN_MENU)

func _process(_delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_timer_label.text = "%.1f" % LoopManager.remaining_time_sec

func _on_state_changed(state: int) -> void:
	_update_panels(state as GameManager.GameState)

func _update_panels(state: GameManager.GameState) -> void:
	_idle_panel.visible = state == GameManager.GameState.IDLE
	_play_ended_panel.visible = (
		state == GameManager.GameState.PLAY_ENDED
		or state == GameManager.GameState.OVER_LIMIT
	)
	_clear_panel.visible = state == GameManager.GameState.CLEAR

func _refresh_ghost_list() -> void:
	for child in _ghost_list.get_children():
		child.queue_free()

	for i in LoopManager.ghost_count:
		var ghost: GhostData = LoopManager.ghosts[i]
		var row := HBoxContainer.new()

		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = GHOST_ROW_COLOR_SIZE
		color_rect.color = ghost.color
		row.add_child(color_rect)

		var label := Label.new()
		label.text = "Ghost %d" % (i + 1)
		label.add_theme_font_size_override("font_size", GHOST_ROW_FONT_SIZE)
		row.add_child(label)

		var btn := Button.new()
		btn.text = "×"
		btn.add_theme_font_size_override("font_size", GHOST_ROW_BTN_FONT_SIZE)
		var idx := i
		btn.pressed.connect(func(): _on_delete_ghost(idx))
		row.add_child(btn)

		_ghost_list.add_child(row)

func _on_save_pressed() -> void:
	var data := RecordingManager.build_ghost_data()
	LoopManager.add_ghost(data)
	GameManager.save_ghost()
	_refresh_ghost_list()

func _on_discard_pressed() -> void:
	GameManager.discard_ghost()

func _on_delete_ghost(index: int) -> void:
	LoopManager.remove_ghost(index)
	GameManager.continue_after_delete()
	_refresh_ghost_list()

# _setup_save_feedback(): 3案すべてに使うノードをコードで作って HUD に追加する。
#   エディタでノードを置かなくても動く。HUD(CanvasLayer)直下に後から add_child
#   するので、自動的にゲーム画面の最前面に表示される。
func _setup_save_feedback() -> void:
	# 案1：ホワイトアウト用の白い四角（普段は透明）
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 1)
	_flash_rect.modulate.a = 0.0
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)  # 画面いっぱい
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE    # クリックを邪魔しない
	add_child(_flash_rect)

	# 案2：ノイズ用の四角に「シェーダー」を貼る
	#   シェーダー = 全ピクセルの色をGPUで計算するミニプログラム。
	#   intensity という値を 1→0 に動かすと、ノイズが出て消える。
	_noise_rect = ColorRect.new()
	_noise_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_noise_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_noise_rect.visible = false
	var shader := Shader.new()
	shader.code = _NOISE_SHADER_CODE        # 下で定義しているシェーダー本体
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("intensity", 0.0)
	_noise_rect.material = mat
	add_child(_noise_rect)

	# 案3：「保存しました」テキスト（画面中央・普段は透明）
	_saved_label = Label.new()
	_saved_label.text = "保存しました"
	_saved_label.add_theme_font_size_override("font_size", 48)  # 文字を大きく
	_saved_label.add_theme_color_override("font_color", Color.WHITE)
	_saved_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_saved_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_saved_label.set_anchors_preset(Control.PRESET_FULL_RECT)   # 画面全体に広げて中央寄せ
	_saved_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_saved_label.modulate.a = 0.0
	_saved_label.visible = false
	add_child(_saved_label)

# _play_save_feedback(): 保存された瞬間（ghost_saved）に呼ばれる入口。
#   save_effect の設定に応じて、3案のどれを再生するか振り分ける。
#   match は他言語の switch に近い「値で分岐」する書き方。
func _play_save_feedback() -> void:
	match save_effect:
		SaveEffect.WHITEOUT:
			_effect_whiteout()
		SaveEffect.NOISE:
			_effect_noise()
		SaveEffect.TEXT_SHAKE:
			_effect_text_shake()

# 案1：ホワイトアウト。パッと白くして、ゆっくり消す。
#   Tween = 時間に沿って値を自動で変化させる仕組み。ここでは透明度(a)を動かす。
func _effect_whiteout() -> void:
	_flash_rect.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_flash_rect, "modulate:a", 0.9, 0.06)  # 0.06秒で一気に白く
	tw.tween_property(_flash_rect, "modulate:a", 0.0, 0.4)   # 0.4秒でフェードアウト

# 案2：ランダムノイズが走る。シェーダーの intensity を 1→0 に動かして出して消す。
#   shader_parameter/intensity という書き方で、シェーダー内の値を Tween で動かせる。
func _effect_noise() -> void:
	var mat := _noise_rect.material as ShaderMaterial
	mat.set_shader_parameter("intensity", 1.0)  # まず最大表示
	_noise_rect.visible = true
	var tw := create_tween()
	tw.tween_property(mat, "shader_parameter/intensity", 0.0, 0.45)  # 0.45秒で消す
	await tw.finished        # アニメ終了を待つ
	_noise_rect.visible = false

# 案3：「保存しました」を出しつつ、画面を一瞬ブレさせる。
#   テキストのフェードと画面揺れを“同時”に走らせている。
func _effect_text_shake() -> void:
	# テキスト：フェードイン → 少し待つ → フェードアウト
	_saved_label.modulate.a = 0.0
	_saved_label.visible = true
	var tw := create_tween()
	tw.tween_property(_saved_label, "modulate:a", 1.0, 0.1)
	tw.tween_interval(0.5)
	tw.tween_property(_saved_label, "modulate:a", 0.0, 0.3)

	# 画面揺れ：await を付けずに呼ぶと“並行して”動く（テキストと同時に揺れる）
	_screen_shake(0.25, 8.0)

	await tw.finished
	_saved_label.visible = false

# _screen_shake(duration, strength): 画面を duration 秒間、strength ピクセルの範囲で
#   ランダムに揺らす。ゲームに Camera2D があればカメラを揺らして“画面全体”が揺れる。
#   無ければ HUD 層だけ揺らす（テキストが揺れるので最低限の演出になる）。
func _screen_shake(duration: float, strength: float) -> void:
	var cam := get_viewport().get_camera_2d()  # 現在有効なカメラ（無ければ null）
	var original := cam.offset if cam else Vector2.ZERO  # 元のズレ位置を覚えておく
	var elapsed := 0.0
	while elapsed < duration:
		# 毎フレーム、ランダムな小さなズレを与える
		var off := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		if cam:
			cam.offset = original + off
		else:
			offset = off   # CanvasLayer.offset（HUD層だけ揺れる代替）
		await get_tree().process_frame   # 1フレーム進むのを待つ
		elapsed += get_process_delta_time()
	# 揺れ終わったら元に戻す
	if cam:
		cam.offset = original
	else:
		offset = Vector2.ZERO

# 案2で使うノイズシェーダーの本体（GLSL風の言語で書く別言語）。
#   const にしておくと書き換わらない。エディタの「シェーダーエディタ」で
#   いじりたければ、この文字列を .gdshader ファイルに移して load() しても良い。
const _NOISE_SHADER_CODE := """
shader_type canvas_item;

// スクリプト側から動かす値。0で透明、1でノイズ最大。
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

// 簡易的な疑似乱数（同じ入力なら同じ値）
float rand(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	// 画面をマス目に区切ってザラザラのノイズを作る
	vec2 cell = floor(UV * vec2(160.0, 120.0));
	float n = rand(cell + floor(TIME * 30.0)); // TIMEで毎フレーム変化＝チラつく

	// 横方向に走る明るいバンド（時間で縦に流れる＝“走る”感じ）
	float band = smoothstep(0.45, 0.5, fract(UV.y * 8.0 - TIME * 3.0));
	n = mix(n, 1.0, band * 0.3);

	// intensity で全体の出方を制御。0なら完全に透明。
	float a = n * intensity;
	COLOR = vec4(vec3(n), a);
}
"""
