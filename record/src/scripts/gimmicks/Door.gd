## 開閉する扉ギミック。
## reset_state() / activate() / deactivate() でダックタイピング対応。
extends AnimatableBody2D

@export var starts_open: bool = false

@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	reset_state()

func activate() -> void:
	_set_open(true)

func deactivate() -> void:
	_set_open(false)

func reset_state() -> void:
	_set_open(starts_open)

func _set_open(open: bool) -> void:
	if _collision:
		_collision.set_deferred("disabled", open)
	visible = not open
