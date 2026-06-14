## テキストを出しつつ、画面を一瞬ブレさせる。
## 連打されたら前回の再生を止めて最初からやり直す（リスタート）。
extends PostProcess

@export var shake_duration: float = 0.25
@export var shake_strength: float = 8.0

@onready var _label: Label = $Label

var _tween: Tween
## 揺れの世代カウンタ。再生のたびに増やし、古い揺れループを終了させる。
var _shake_id: int = 0
var _shake_active: bool = false
var _base_offset: Vector2 = Vector2.ZERO

func play() -> void:
	# 前回の再生を破棄してリスタート（連打で時間が短くならないように）
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_label.modulate.a = 0.0
	_label.visible = true

	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 1.0, 0.1)
	_tween.tween_interval(0.5)
	_tween.tween_property(_label, "modulate:a", 0.0, 0.3)
	# 終了時の非表示は await ではなくコールバックで行う（kill しても誤発火しない）
	_tween.tween_callback(func() -> void: _label.visible = false)

	_restart_shake()

## 画面を shake_duration 秒間、shake_strength px の範囲でランダムに揺らす。
## _shake_id を使って、連打時は最新の揺れだけが offset を管理する。
func _restart_shake() -> void:
	_shake_id += 1
	var id: int = _shake_id

	var cam := get_viewport().get_camera_2d()
	# 揺れ始める瞬間の offset を基準に。連打中（既に揺れている）は基準を取り直さない。
	if not _shake_active:
		_base_offset = cam.offset if cam else Vector2.ZERO
		_shake_active = true

	var elapsed: float = 0.0
	while elapsed < shake_duration:
		if id != _shake_id:
			return  # 新しい再生に置き換えられた（offset は新しい側が管理）
		var off := Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		if cam:
			cam.offset = _base_offset + off
		else:
			offset = off
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	# 最新の揺れだけがここに到達する。基準位置に戻して終了。
	if cam:
		cam.offset = _base_offset
	else:
		offset = Vector2.ZERO
	_shake_active = false
