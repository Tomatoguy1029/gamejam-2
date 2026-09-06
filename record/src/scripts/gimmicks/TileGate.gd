## Reusable gate target that swaps between a closed and open tile.
extends Node

@export var tile_map_path: NodePath
@export var gate_cell: Vector2i
@export var source_id: int = 1
@export var closed_gate: Vector2i = Vector2i(2, 2)
@export var open_gate: Vector2i = Vector2i(3, 2)
@export var starts_open: bool = false

@onready var _tile_map: TileMapLayer = get_node_or_null(tile_map_path) as TileMapLayer

func _ready() -> void:
	reset_state()

func activate() -> void:
	_set_open(true)

func deactivate() -> void:
	_set_open(false)

func reset_state() -> void:
	_set_open(starts_open)

func _set_open(open: bool) -> void:
	if _tile_map:
		_tile_map.set_cell(gate_cell, source_id, open_gate if open else closed_gate)
