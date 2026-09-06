## Plays the bulb-to-blob sequence, then reveals the separate slime character.
extends Node2D

@onready var _spawn_animation: AnimatedSprite2D = $SpawnAnimation
@onready var _character: Sprite2D = $Character
@onready var _bulb: Sprite2D = $Bulb

func _ready() -> void:
	_spawn_animation.animation_finished.connect(_on_animation_finished)
	show_character()

func play_spawn() -> void:
	_bulb.hide()
	_character.hide()
	_character.position = Vector2(-64, -64)
	_spawn_animation.show()
	_spawn_animation.stop()
	_spawn_animation.frame = 0
	_spawn_animation.play(&"spawn")

func is_spawn_playing() -> bool:
	return _spawn_animation.is_playing()

func show_character() -> void:
	_spawn_animation.hide()
	_bulb.hide()
	_character.show()

func keep_bulb() -> void:
	_spawn_animation.hide()
	_character.hide()
	_bulb.show()

func _on_animation_finished() -> void:
	if _spawn_animation.animation == &"spawn":
		_spawn_animation.hide()
		_character.show()
		_bulb.show()
