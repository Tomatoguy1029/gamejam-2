## 案2：ランダムノイズが走る。シェーダーの intensity を 1→0 に動かして出して消す。
extends PostProcess

@export var _duration: float = 0.5
@onready var _rect: ColorRect = $ColorRect

func play() -> void:
	var mat := _rect.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("intensity", 1.0)  # まず最大表示
	_rect.visible = true
	var tw := create_tween()
	tw.tween_property(mat, "shader_parameter/intensity", 0.0, _duration)  # 0.45秒で消す
	await tw.finished
	_rect.visible = false
