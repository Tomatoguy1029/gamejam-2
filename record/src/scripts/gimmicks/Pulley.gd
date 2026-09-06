## 滑車ギミック（カウンターウェイト式）。
## ロープで繋がれた 2 つのカゴが常に逆方向へ動く。乗っているアクターの数が多いほうが下がり、
## 数が釣り合っている間はその場で静止する（初期位置へは戻らない）。
##
## 重さの検出は各カゴの WeightArea（Area2D / collision_mask = ALL_ACTORS）で行う。
## PressurePlate と同じくプレイヤーとすべてのゴーストを拾うので、
## 「1 本目の録画でゴーストを片方に乗せ、上がってきたもう片方に自分が乗る」が成立する。
##
## カゴは AnimatableBody2D なので、上に乗ったアクターの追従は move_and_slide() の
## ムービングプラットフォーム機能に任せられる（ActorBase のコメント参照）。
##
## move_range / move_speed はこのノードのローカル単位。Pulley 自体を拡大縮小すると
## 見かけの距離・速度も比例して変わるため、レベルには scale 1 で配置する想定。
extends Node2D

## カゴが初期位置から上下に動ける距離（px・片側）
@export var move_range: float = 260.0
## カゴの移動速度（px/s）。乗っている人数の差の「大きさ」によらず一定。
@export var move_speed: float = 150.0

@export_group("見た目")
@export var rope_color: Color = Color(0.75, 0.68, 0.5)
@export var rope_width: float = 5.0
@export var wheel_radius: float = 26.0
@export var wheel_color: Color = Color(0.45, 0.32, 0.18)

@onready var _basket_a: AnimatableBody2D = $BasketA
@onready var _basket_b: AnimatableBody2D = $BasketB
@onready var _wheel: Marker2D = $Wheel

## A の初期位置からの下向きオフセット（px）。B には符号を反転して適用する。
var _offset: float = 0.0

## 各カゴに乗っているアクター。PressurePlate と同じく配列で管理する。
## 空にするときは必ず clear() を使う（参照を差し替えるとシグナル側の捕捉とずれる）。
var _riders_a: Array[Node] = []
var _riders_b: Array[Node] = []

var _home_a: Vector2
var _home_b: Vector2

func _ready() -> void:
	_home_a = _basket_a.position  # 配置時の位置を基準として記録
	_home_b = _basket_b.position

	var area_a: Area2D = _basket_a.get_node("WeightArea")
	var area_b: Area2D = _basket_b.get_node("WeightArea")
	area_a.body_entered.connect(func(body: Node2D) -> void: _riders_a.append(body))
	area_a.body_exited.connect(func(body: Node2D) -> void: _riders_a.erase(body))
	area_b.body_entered.connect(func(body: Node2D) -> void: _riders_b.append(body))
	area_b.body_exited.connect(func(body: Node2D) -> void: _riders_b.erase(body))

	reset_state()

func _physics_process(delta: float) -> void:
	# アクターが止まっている状態でカゴだけ動くと、乗っている側が置き去りになる。
	# ActorBase と同じく PLAYING 中だけ動かす。
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	var dir: int = signi(_riders_a.size() - _riders_b.size())
	if dir == 0:
		return  # 釣り合っている間はその場で静止

	var next: float = clampf(_offset + float(dir) * move_speed * delta, -move_range, move_range)
	if next == _offset:
		return  # 可動端に達している
	_offset = next
	_apply_offset()

## WorldResetManager から呼ばれる。カゴを初期位置へ戻す。
func reset_state() -> void:
	_riders_a.clear()
	_riders_b.clear()
	_offset = 0.0
	_apply_offset()

func _apply_offset() -> void:
	_basket_a.position = _home_a + Vector2(0.0, _offset)
	_basket_b.position = _home_b - Vector2(0.0, _offset)
	queue_redraw()  # ロープを引き直す

## 滑車とロープを描く。自身の描画は子（カゴ）より先に処理されるので、
## ロープは自動的にカゴの後ろへ回る。
func _draw() -> void:
	var wheel_pos: Vector2 = _wheel.position
	var over_a := Vector2(_basket_a.position.x, wheel_pos.y)
	var over_b := Vector2(_basket_b.position.x, wheel_pos.y)

	# A のカゴ → 滑車の上 → B のカゴ を 1 本のロープとして繋ぐ
	draw_polyline(PackedVector2Array([
		_basket_a.position, over_a, over_b, _basket_b.position,
	]), rope_color, rope_width)

	draw_circle(wheel_pos, wheel_radius, wheel_color)
	draw_arc(wheel_pos, wheel_radius, 0.0, TAU, 32, rope_color, rope_width * 0.6)
