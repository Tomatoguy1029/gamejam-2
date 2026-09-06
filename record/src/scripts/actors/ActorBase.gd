## プレイヤー・ゴースト共通の物理挙動。
## _get_input() をオーバーライドすることで入力源を切り替える。
##
## 接地・足場追従は Godot 標準の CharacterBody2D 機能に任せる：
##   - is_on_floor() で接地判定
##   - move_and_slide() が「今乗っている足場（横移動・ジャンプ中のゴースト含む）
##     の速度」を自動で motion に加算してくれる（ムービングプラットフォーム機能）
## そのため velocity は常に「足場に対する相対速度」だけを表せばよく、
## 「上に乗っている時だけ足場速度を手で合成する」ような場当たり実装は不要。
extends CharacterBody2D

@export var move_speed: float = 300.0
@export var jump_velocity: float = -700.0
@export var gravity: float = 1800.0
@export var climb_speed: float = 200.0
## 横方向の加減速（px/s^2）。既定値は旧実装の move_speed * 8 相当。
@export var accel: float = 2400.0

## 移動パラメータのリソース。割り当てるとこの値で上書きする（src/data/*.tres）。
## プレイヤーとゴーストで同じ .tres を共有すれば挙動が一致する。
@export var movement_stats: MovementStats

var _ladder_count: int = 0
var is_on_ladder: bool:
	get: return _ladder_count > 0

func _ready() -> void:
	# stats が割り当てられていれば、その値で各パラメータを上書き
	if movement_stats != null:
		move_speed = movement_stats.move_speed
		jump_velocity = movement_stats.jump_velocity
		gravity = movement_stats.gravity
		climb_speed = movement_stats.climb_speed
		accel = movement_stats.accel

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
	# はしご：重力を無視して上下移動
	if is_on_ladder:
		velocity.x = input.get("move_dir", 0.0) * move_speed
		if input.get("move_up", false):
			velocity.y = -climb_speed
		elif input.get("move_down", false):
			velocity.y = climb_speed
		else:
			velocity.y = 0.0
		return

	# 重力（空中のみ）。接地中は move_and_slide が縦速度を受け止める。
	if not is_on_floor():
		velocity.y += gravity * delta

	# ジャンプ
	if input.get("jump", false) and is_on_floor():
		velocity.y = jump_velocity

	# 横移動
	var target_x: float = input.get("move_dir", 0.0) * move_speed
	velocity.x = move_toward(velocity.x, target_x, accel * delta)
