## GhostData を再生する ActorBase サブクラス。
## LoopManager の共通クロック（loop_tick）を参照してフレームを索引する。
extends "res://src/scripts/actors/ActorBase.gd"

var _ghost_data: GhostData = null

## LoopManager.spawn_all() からスポーン時に呼ばれる初期化メソッド。
func initialize(data: GhostData) -> void:
	_ghost_data = data

	# 半透明カラーを Sprite2D に適用
	var sprite := get_node_or_null("Sprite2D")
	if sprite is Sprite2D:
		var c := data.color
		sprite.modulate = Color(c.r, c.g, c.b, 0.6)

func _get_input() -> Dictionary:
	if _ghost_data == null:
		return super._get_input()

	var frame := _ghost_data.get_frame(LoopManager.loop_tick)
	return {
		move_dir = frame.move_dir,
		jump = frame.jump,
		interact = frame.interact,
		move_up = frame.move_up,
		move_down = frame.move_down,
	}
