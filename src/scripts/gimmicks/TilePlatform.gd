## A TileMapLayer platform controlled by a pressure plate or other activate target.
## Put only this platform's tiles in the layer so its visual and collision can
## change independently of the permanent terrain.
extends TileMapLayer

@export var starts_active: bool = false
@export var inactive_modulate: Color = Color(0.65, 0.65, 0.65, 0.35)
@export var active_modulate: Color = Color.WHITE

func _ready() -> void:
	reset_state()

func activate() -> void:
	_set_active(true)

func deactivate() -> void:
	_set_active(false)

func reset_state() -> void:
	_set_active(starts_active)

func _set_active(active: bool) -> void:
	modulate = active_modulate if active else inactive_modulate
	collision_enabled = active
