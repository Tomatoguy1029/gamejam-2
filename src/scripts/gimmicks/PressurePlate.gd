## 圧力板ギミック（モーメンタリ）。
## 重みが乗っている間だけ ON → ターゲットの activate/deactivate を呼び、シグナルも発火。
extends Area2D

signal plate_pressed
signal plate_released

@export var target_paths: Array[NodePath] = []
@export var default_color: Color = Color(0.5, 0.4, 0.2)
@export var press_color: Color = Color(0.3, 0.25, 0.1)
@export var press_offset: float = 6.0

var _targets: Array[Node] = []
var _overlapping: Array[Node] = []
var _is_active: bool = false
var _tween: Tween
var _home_pos: Vector2

@onready var _color_rect: ColorRect = $ColorRect

func _ready() -> void:
	for path in target_paths:
		var t := get_node_or_null(path)
		if t != null:
			_targets.append(t)

	_home_pos = _color_rect.position  # 配置時の位置を基準として記録
	_color_rect.color = default_color
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func reset_state() -> void:
	_overlapping.clear()
	_is_active = false
	if _tween:
		_tween.kill()
	if _color_rect:
		_color_rect.position = _home_pos
		_color_rect.color = default_color

func _on_body_entered(body: Node2D) -> void:
	_overlapping.append(body)
	if not _is_active:
		_set_active(true)

func _on_body_exited(body: Node2D) -> void:
	_overlapping.erase(body)
	if _overlapping.is_empty() and _is_active:
		_set_active(false)

func _set_active(active: bool) -> void:
	_is_active = active
	_animate(active)

	if active:
		plate_pressed.emit()
	else:
		plate_released.emit()

	for target in _targets:
		if active and target.has_method("activate"):
			target.activate()
		elif not active and target.has_method("deactivate"):
			target.deactivate()

func _animate(pressed: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)

	var target_pos := _home_pos + Vector2(0.0, press_offset) if pressed else _home_pos
	var target_color := press_color if pressed else default_color

	_tween.tween_property(_color_rect, "position", target_pos, 0.07).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_color_rect, "color", target_color, 0.07)
