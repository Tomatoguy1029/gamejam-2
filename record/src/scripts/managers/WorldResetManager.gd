## ループ開始時にレベル内の全ギミックを初期状態へ戻す。Autoload。
## IGimmickResettable の代わりに has_method("reset_state") でダックタイピング。
extends Node

var _level: Node = null

func _ready() -> void:
	GameManager.state_changed.connect(func(state):
		if state == GameManager.GameState.IDLE:
			reset_all()
	)
	GameManager.room_retried.connect(reset_all)

func set_level(level: Node) -> void:
	_level = level

## Level 以下の全ノードを再帰探索して reset_state() を呼ぶ。
func reset_all() -> void:
	if _level == null:
		return
	_reset_recursive(_level)

func _reset_recursive(node: Node) -> void:
	if node.has_method("reset_state"):
		node.reset_state()
	for child in node.get_children():
		_reset_recursive(child)
