## Reusable pressure plate for tiles drawn on any TileMapLayer.
extends Area2D

signal plate_pressed
signal plate_released

@export var tile_map_path: NodePath
@export var button_cell: Vector2i
@export var source_id: int = 1
@export var released_button: Vector2i = Vector2i(0, 3)
@export var pressed_button: Vector2i = Vector2i(0, 4)
## Nodes with activate() / deactivate(), such as TileGate, TilePlatform, or Lamp.
@export var target_paths: Array[NodePath] = []

var _is_pressed: bool = false
var _targets: Array[Node] = []
@onready var _tile_map: TileMapLayer = get_node_or_null(tile_map_path) as TileMapLayer

func _ready() -> void:
	for path in target_paths:
		var target := get_node_or_null(path)
		if target != null:
			_targets.append(target)
	reset_state()

func _physics_process(_delta: float) -> void:
	# Check all occupants so one actor leaving does not release another's plate.
	# Polling also restores the correct state after a retry or loop reset.
	var pressed := has_overlapping_bodies()
	if pressed != _is_pressed:
		_set_pressed(pressed)

func reset_state() -> void:
	_set_pressed(false)

func _set_pressed(pressed: bool) -> void:
	_is_pressed = pressed
	if _tile_map:
		_tile_map.set_cell(button_cell, source_id, pressed_button if pressed else released_button)

	if pressed:
		plate_pressed.emit()
	else:
		plate_released.emit()

	for target in _targets:
		if pressed and target.has_method("activate"):
			target.activate()
		elif not pressed and target.has_method("deactivate"):
			target.deactivate()
