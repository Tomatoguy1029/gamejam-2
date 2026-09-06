## ループ・ゴーストのライフサイクル管理と共通クロック。Autoload。
extends Node

@export var max_ghosts: int = 3
## アクター幅 + マージン（px）
@export var spawn_offset_x: float = 64.0
## Time to slide a formed slime from the shared bulb to its starting slot.
@export var spawn_move_sec: float = 0.25
@export var base_spawn_position: Vector2 = Vector2(200.0, 1000.0)
@export var time_limit_sec: float = 30.0

var player_actor_scene: PackedScene
var ghost_actor_scene: PackedScene

## Array[GhostData]
var ghosts: Array = []

var ghost_count: int:
	get: return ghosts.size()

var is_at_limit: bool:
	get: return ghosts.size() >= max_ghosts

var current_loop_index: int:
	get: return ghosts.size()

# ── クロック ─────────────────────────────────────────────────────────────────
var loop_tick: int = 0

var max_tick: int:
	get: return int(time_limit_sec * Engine.physics_ticks_per_second)

var remaining_time_sec: float:
	get: return maxf(0.0, float(max_tick - loop_tick) / float(Engine.physics_ticks_per_second))

var _clock_running: bool = false

# ── スポーン管理 ──────────────────────────────────────────────────────────────
var _ghost_instances: Array[Node2D] = []
var _player_instance: Node2D = null
var _spawn_parent: Node = null
var is_spawning: bool = false
var _spawn_effect: Node2D
var _spawn_queue: Array[Node2D] = []
var _spawn_index: int = 0
var _spawn_move_elapsed: float = 0.0

# ── ゴーストカラー ────────────────────────────────────────────────────────────
const GHOST_COLORS: Array[Color] = [
	Color(1.0, 0.2, 0.2),    # 赤
	Color(1.0, 0.6, 0.0),    # オレンジ
	Color(1.0, 1.0, 0.0),    # 黄
	Color(0.2, 1.0, 0.2),    # 緑
	Color(0.2, 0.5, 1.0),    # 青
	Color(0.8, 0.2, 1.0),    # 紫
	Color(1.0, 1.0, 1.0),    # 白
	Color(0.2, 0.2, 0.2),    # 黒
]

func _ready() -> void:
	player_actor_scene = load("res://scenes/actors/PlayerActor.tscn")
	ghost_actor_scene = load("res://scenes/actors/GhostActor.tscn")

	GameManager.loop_started.connect(_on_loop_started)
	GameManager.ghost_discarded.connect(_on_ghost_discarded)
	GameManager.room_retried.connect(_on_room_retried)
	GameManager.state_changed.connect(_on_state_changed)

func _physics_process(_delta: float) -> void:
	if is_spawning:
		_update_spawn(_delta)
		return
	if not _clock_running:
		return
	loop_tick += 1
	if loop_tick >= max_tick:
		_clock_running = false
		GameManager.end_play(false)  # タイムアップ

# ── 公開 API ──────────────────────────────────────────────────────────────────

func set_spawn_parent(parent: Node) -> void:
	_spawn_parent = parent

## ゴーストを1体追加する。上限に達している場合は追加せず false を返す。
func add_ghost(data: GhostData) -> bool:
	if is_at_limit:
		return false
	data.ghost_index = ghosts.size()
	data.color = get_color_for_index(data.ghost_index)
	ghosts.append(data)
	return true

## 録画(GhostData)を保存する。
## 判定は「追加する前に空き枠があるか」で行う。最後の枠を埋める保存は正常扱い。
##   - 空き枠あり → 保存して ghost_saved（noise 演出）+ IDLE
##   - 空き枠なし → 保存できず over_limit（録画容量なし演出）のみ
func save_recording(data: GhostData) -> void:
	if is_at_limit:
		GameManager.trigger_over_limit()  # 空き枠なし＝保存不可
		return
	add_ghost(data)
	# 初回保存のみ：短い Noise の代わりに長い巻き戻し演出（軌跡の逆再生）を再生し、
	# 終わってから IDLE（再スポーン）へ。
	if not GameManager.first_rewind_played:
		GameManager.first_rewind_played = true
		await _play_first_rewind()
		GameManager.change_state(GameManager.GameState.IDLE)
		return
	GameManager.save_ghost()  # 通常: 短い noise 演出 + IDLE

## 初回保存時の巻き戻し演出。長い Noise を出しつつ、プレイヤーの軌跡を逆再生する。
## 再生が終わってから保存→IDLE（再スポーン）へ進む。
func _play_first_rewind() -> void:
	GameManager.rewind_started.emit()  # RetryEffect が長い Noise を再生（入力ロック付き）
	if is_instance_valid(_player_instance) and _player_instance.has_method("rewind"):
		await _player_instance.rewind()

## ステージ切り替え時にゴーストとアクターを全消去
func ClearAll() -> void:
	ghosts.clear()
	_despawn_all()
	loop_tick = 0
	_clock_running = false

func remove_ghost(index: int) -> void:
	if index < 0 or index >= ghosts.size():
		return
	ghosts.remove_at(index)
	# インデックスを詰め直す
	for i in ghosts.size():
		ghosts[i].ghost_index = i

func get_color_for_index(index: int) -> Color:
	return GHOST_COLORS[index % GHOST_COLORS.size()]

func get_spawn_position(index: int) -> Vector2:
	return base_spawn_position + Vector2(index * spawn_offset_x, 0.0)

# ── イベントハンドラ ──────────────────────────────────────────────────────────

## IDLE に入った時点でワールドを初期化し、アクターを配置する。
## こうすることで、保存/破棄/削除の「その瞬間」にリセットが見え、
## space 押下後にリセットが走る違和感が無くなる。
func _on_state_changed(state: int) -> void:
	if state == GameManager.GameState.IDLE:
		_despawn_all()
		_spawn_all()
		loop_tick = 0
		_clock_running = false
	elif state == GameManager.GameState.MAIN_MENU:
		# タイトルに戻ったらゴーストを全消去する。
		# （この後 HUD のリスト再描画が走り、Ghost1 等の行が消える）
		ClearAll()

func _on_loop_started(_loop_index: int) -> void:
	# アクターは IDLE 時に配置済み。space ではクロックを開始するだけ。
	loop_tick = 0
	_clock_running = true

func _on_ghost_discarded() -> void:
	pass  # 枠消費なし・状態変化は GameManager.discard_ghost() 済み

func _on_room_retried() -> void:
	ghosts.clear()
	_despawn_all()
	loop_tick = 0
	_clock_running = false

# ── スポーン ──────────────────────────────────────────────────────────────────

func _spawn_all() -> void:
	if _spawn_parent == null:
		return

	for i in ghosts.size():
		var ghost: Node2D = ghost_actor_scene.instantiate()
		_spawn_parent.add_child(ghost)
		ghost.global_position = get_spawn_position(i)

		# GhostController に GhostData とクロック参照を渡す
		if ghost.has_method("initialize"):
			ghost.initialize(ghosts[i])

		# 衝突レイヤーを動的設定
		_set_ghost_collision(ghost, i)

		_ghost_instances.append(ghost)

	# プレイヤーをスポーン
	_player_instance = player_actor_scene.instantiate()
	_spawn_parent.add_child(_player_instance)
	_player_instance.global_position = get_spawn_position(ghosts.size())

	_spawn_queue.assign(_ghost_instances)
	_spawn_queue.append(_player_instance)
	for actor in _spawn_queue:
		actor.hide()
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		actor.get_node("CollisionShape2D").set_deferred("disabled", true)
	_spawn_effect = load("res://scenes/actors/SlimeVisual.tscn").instantiate()
	_spawn_effect.name = "SpawnBulb"
	_spawn_parent.add_child(_spawn_effect)
	_spawn_effect.global_position = base_spawn_position
	_spawn_index = 0
	is_spawning = true
	_begin_spawn()

func _begin_spawn() -> void:
	_spawn_move_elapsed = 0.0
	_spawn_effect.play_spawn()
	# Tint the emerging slime, while keeping the stationary bulb neutral.
	_spawn_effect.get_node("Character").modulate = _spawn_queue[_spawn_index].get_node("SlimeVisual").modulate

func _update_spawn(delta: float) -> void:
	if not is_instance_valid(_spawn_effect) or not is_instance_valid(_spawn_parent):
		_despawn_all()
		return
	if _spawn_effect.is_spawn_playing():
		return
	_spawn_move_elapsed += delta
	var actor := _spawn_queue[_spawn_index]
	var progress := clampf(_spawn_move_elapsed / maxf(spawn_move_sec, 0.001), 0.0, 1.0)
	var character: Sprite2D = _spawn_effect.get_node("Character")
	character.global_position = base_spawn_position.lerp(actor.global_position, progress) + Vector2(-64, -64)
	if progress < 1.0:
		return
	actor.show()
	_spawn_effect.keep_bulb()
	_spawn_index += 1
	if _spawn_index < _spawn_queue.size():
		_begin_spawn()
	else:
		for spawned in _spawn_queue:
			spawned.process_mode = Node.PROCESS_MODE_INHERIT
			spawned.get_node("CollisionShape2D").set_deferred("disabled", false)
		_spawn_queue.clear()
		is_spawning = false

func _despawn_all() -> void:
	is_spawning = false
	_spawn_queue.clear()
	if is_instance_valid(_spawn_effect):
		_spawn_effect.queue_free()
	_spawn_effect = null
	for inst in _ghost_instances:
		if is_instance_valid(inst):
			inst.queue_free()
	_ghost_instances.clear()

	if is_instance_valid(_player_instance):
		_player_instance.queue_free()
	_player_instance = null

## Layer: 1=World, 2=Player, 3=Ghost_0, 4=Ghost_1, 5=Ghost_2, 6=Ghost_3
## ゴースト N は World + Ghost_0〜Ghost_{N-1} とのみ衝突する。
## FloorDetector も同じマスクを設定し、古いゴーストの頭に乗れるようにする。
func _set_ghost_collision(body: Node2D, ghost_index: int) -> void:
	if not body is CharacterBody2D:
		return
	var cb := body as CharacterBody2D
	cb.collision_layer = 1 << (ghost_index + 2)  # Ghost_N レイヤー（bit 2〜5）
	var mask: int = 1  # World（bit 0）
	for i in ghost_index:
		mask |= 1 << (i + 2)  # 自分より古いゴースト
	cb.collision_mask = mask

	# FloorDetector も同じマスクに揃える（ActorBase._ready() より後に呼ばれるため上書き）
	var fd := body.get_node_or_null("FloorDetector")
	if fd is ShapeCast2D:
		fd.collision_mask = mask
