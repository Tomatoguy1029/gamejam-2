## プレイヤー・ゴースト共通の物理挙動。
## _get_input() をオーバーライドすることで入力源を切り替える。
extends CharacterBody2D

@export var move_speed: float = 300.0
@export var jump_velocity: float = -700.0
@export var gravity: float = 1800.0
@export var climb_speed: float = 200.0

var _ladder_count: int = 0
var is_on_ladder: bool:
	get: return _ladder_count > 0

## 足元の接地判定（ShapeCast2D を下向きに設置）
@onready var floor_detector: ShapeCast2D = $FloorDetector

func _ready() -> void:
	# FloorDetector のマスクを本体の collision_mask に自動同期する。
	# これにより PlayerActor は tscn 設定値（61）が、
	# GhostActor は LoopManager が動的設定した値が引き継がれる。
	if floor_detector:
		floor_detector.collision_mask = collision_mask

var is_grounded: bool:
	get: return floor_detector != null and floor_detector.is_colliding()

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	var input := _get_input()
	_apply_physics(input, delta)
	move_and_slide()

## サブクラスがオーバーライドして入力を返す。
func _get_input() -> Dictionary:
	return {move_dir = 0.0, jump = false, interact = false, move_up = false, move_down = false}

func _apply_physics(input: Dictionary, delta: float) -> void:
	var vel := velocity

	if is_on_ladder:
		vel.x = input.get("move_dir", 0.0) * move_speed
		if input.get("move_up", false):
			vel.y = -climb_speed
		elif input.get("move_down", false):
			vel.y = climb_speed
		else:
			vel.y = 0.0
	else:
		# 通常：重力・ジャンプ
		if not is_grounded:
			vel.y += gravity * delta
		elif vel.y > 0.0:
			vel.y = 0.0

		if input.get("jump", false) and is_grounded:
			vel.y = jump_velocity

		vel.x = input.get("move_dir", 0.0) * move_speed

	velocity = vel
