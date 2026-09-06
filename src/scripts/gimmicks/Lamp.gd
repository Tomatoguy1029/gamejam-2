## ボタンのシグナルまたは activate/deactivate で点灯するランプ。
extends Node2D

@export var off_color: Color = Color(0.15, 0.15, 0.15)
@export var on_color: Color = Color(1.0, 0.9, 0.2)

@onready var _color_rect: ColorRect = $ColorRect

func _ready() -> void:
	_color_rect.color = off_color

func activate() -> void:
	_animate(true)

func deactivate() -> void:
	_animate(false)

func reset_state() -> void:
	_color_rect.color = off_color

func _animate(lit: bool) -> void:
	var tween := create_tween()
	tween.tween_property(_color_rect, "color", on_color if lit else off_color, 0.15)
