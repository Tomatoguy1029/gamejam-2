## リトライ時のポストプロセス演出をまとめる親ノード
extends Node

## 保存（ghost_saved）時に再生する演出ノード。
@export var on_save: PostProcess
## 破棄（ghost_discarded）時に再生する演出ノード。
@export var on_discard: PostProcess
## 保存枠が一杯（over_limit）のときに再生する演出ノード。
@export var on_over_limit: PostProcess

func _ready() -> void:
	GameManager.ghost_saved.connect(func() -> void: _play(on_save))
	GameManager.ghost_discarded.connect(func() -> void: _play(on_discard))
	GameManager.over_limit.connect(func() -> void: _play(on_over_limit))

func _play(effect: PostProcess) -> void:
	if effect != null:
		effect.play()
