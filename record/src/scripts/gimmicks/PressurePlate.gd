## 圧力板ギミック（モーメンタリ）。
## 重みが乗っている間だけ ON → ターゲットの activate() / deactivate() を呼ぶ。
extends Area2D

@export var target_paths: Array[NodePath] = []

var _targets: Array[Node] = []
var _overlapping: Array[Node] = []
var _is_active: bool = false

func _ready() -> void:
	for path in target_paths:
		var t := get_node_or_null(path)
		if t != null:
			_targets.append(t)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func reset_state() -> void:
	_overlapping.clear()
	_set_active(false)

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
	for target in _targets:
		if active and target.has_method("activate"):
			target.activate()
		elif not active and target.has_method("deactivate"):
			target.deactivate()
