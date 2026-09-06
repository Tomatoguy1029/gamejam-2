## 案2：ランダムノイズ/歪み。シェーダーの intensity を 1→0 に動かして出して消す。
## 短い版（リトライ・保存時）と長い版（チュートリアル導入時）を _duration で作り分ける。
extends PostProcess

## 演出時間（秒）。短い版はそのまま、長い版は 2.0 程度にする。
@export var _duration: float = 0.5
## 再生中ゲーム入力をブロックするか（長い導入アニメ用）。短い版は false。
@export var lock_input: bool = false
## 長い版用：wave_amplitude を「最後の falloff 秒だけ」シグモイド状に 0 へ落とすか。
@export var amplitude_falloff: bool = false
## amplitude を 0 に落とす時間（秒）。これより前は規定値を維持する。
@export var amplitude_falloff_time: float = 0.5

@onready var _rect: ColorRect = $ColorRect

## 規定の wave_amplitude（初回 play で1度だけ記録し、毎回開始時にここへ戻す）
var _base_amplitude: float = -1.0

func play() -> void:
	var mat := _rect.material as ShaderMaterial
	if mat == null:
		return
	if lock_input:
		GameManager.input_locked = true
	mat.set_shader_parameter("intensity", 1.0)  # まず最大表示
	_rect.visible = true

	# wave_amplitude を規定値で維持 → 最後の falloff 秒だけ S字（sine in-out）で 0 へ。
	# 毎回開始時に規定値へ戻すので、前回 0 まで落ちても次回は規定値から始まる。
	var do_falloff: bool = amplitude_falloff and _duration > amplitude_falloff_time
	if do_falloff:
		if _base_amplitude < 0.0:
			_base_amplitude = mat.get_shader_parameter("wave_amplitude")
		mat.set_shader_parameter("wave_amplitude", _base_amplitude)
		var amp_tw := create_tween()
		amp_tw.tween_interval(_duration - amplitude_falloff_time)
		amp_tw.tween_property(mat, "shader_parameter/wave_amplitude", 0.0, amplitude_falloff_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var tw := create_tween()
	tw.tween_property(mat, "shader_parameter/intensity", 0.0, _duration)
	await tw.finished

	_rect.visible = false
	if lock_input:
		GameManager.input_locked = false
