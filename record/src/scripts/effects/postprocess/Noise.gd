## 案2：ランダムノイズ/歪み。シェーダーの intensity を 1→0 に動かして出して消す。
## 短い版（リトライ・保存時）と長い版（チュートリアル導入時）を _duration で作り分ける。
extends PostProcess

## 演出時間（秒）。短い版はそのまま、長い版は 2.0 程度にする。
@export var _duration: float = 0.5
## 再生中ゲーム入力をブロックするか（長い導入アニメ用）。短い版は false。
@export var lock_input: bool = false

@onready var _rect: ColorRect = $ColorRect

func play() -> void:
	var mat := _rect.material as ShaderMaterial
	if mat == null:
		return
	if lock_input:
		GameManager.input_locked = true
	mat.set_shader_parameter("intensity", 1.0)  # まず最大表示
	_rect.visible = true
	var tw := create_tween()
	tw.tween_property(mat, "shader_parameter/intensity", 0.0, _duration)
	await tw.finished
	_rect.visible = false
	if lock_input:
		GameManager.input_locked = false
