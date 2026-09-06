extends AnimatableBody2D

@export var initial_state: bool = false

@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	reset_state()

func activate() -> void:
	_set_visible(true)

func deactivate() -> void:
	_set_visible(false)

func reset_state() -> void:
	_set_visible(initial_state)

func _set_visible(show: bool) -> void:
	if _collision:
		_collision.set_deferred("disabled", not show)
	self.visible = show
