## ホワイトアウト
extends PostProcess

@onready var _rect: ColorRect = $ColorRect

func play() -> void:
	_rect.modulate.a = 0.0
	_rect.visible = true
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 0.9, 0.06)  # 0.06秒で一気に白く
	tw.tween_property(_rect, "modulate:a", 0.0, 0.4)    # 0.4秒でフェードアウト
	await tw.finished
	_rect.visible = false
