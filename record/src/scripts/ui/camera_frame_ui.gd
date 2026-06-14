## CameraFrame のルート。録画の残り時間（タイマー）表示を更新する。
## 角の枠・十字・REC・バッテリーは子ノードが担当。
extends Control

@onready var _timer_label: Label = $RecInfo/TimerLabel

func _process(_delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_timer_label.text = "%.1f" % LoopManager.remaining_time_sec
