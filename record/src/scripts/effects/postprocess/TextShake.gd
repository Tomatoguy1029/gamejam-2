## テキストを出しつつ、画面を一瞬ブレさせる。
extends PostProcess

@export var shake_duration: float = 0.25
@export var shake_strength: float = 8.0

@onready var _label: Label = $Label

func play() -> void:
	_label.modulate.a = 0.0
	_label.visible = true

	var tw := create_tween()
	tw.tween_property(_label, "modulate:a", 1.0, 0.1)
	tw.tween_interval(0.5)
	tw.tween_property(_label, "modulate:a", 0.0, 0.3)

	_screen_shake(shake_duration, shake_strength)

	await tw.finished
	_label.visible = false

## 画面を duration 秒間、strength px の範囲でランダムに揺らす
func _screen_shake(duration: float, strength: float) -> void:
	var cam := get_viewport().get_camera_2d()
	var original := cam.offset if cam else Vector2.ZERO
	var elapsed := 0.0
	while elapsed < duration:
		var off := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		if cam:
			cam.offset = original + off
		else:
			offset = off
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if cam:
		cam.offset = original
	else:
		offset = Vector2.ZERO
