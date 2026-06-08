## ゲームシーンのルートスクリプト。
## Manager 群の接続・レベルロード・ゲームフロー全体を仲介する。
extends Node2D

@export var initial_level: PackedScene

var _current_level: Node2D = null

func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.room_retried.connect(_on_room_retried)
	GameManager.next_stage_requested.connect(_on_next_stage_requested)
	GameManager.return_to_title_requested.connect(_on_return_to_title)

	_load_level(initial_level)
	GameManager.start_game()  # → IDLE

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state == GameManager.GameState.IDLE:
		if Input.is_action_just_pressed("jump"):
			_start_loop()

# ── ループ開始 ────────────────────────────────────────────────────────────────

func _start_loop() -> void:
	LoopManager.set_spawn_parent(_current_level)
	GameManager.start_loop(LoopManager.current_loop_index)

# ── レベル管理 ────────────────────────────────────────────────────────────────

func _load_level(level_scene: PackedScene) -> void:
	if level_scene == null:
		return

	if is_instance_valid(_current_level):
		_current_level.queue_free()

	_current_level = level_scene.instantiate()
	add_child(_current_level)
	move_child(_current_level, 0)  # HUD より背面に

	WorldResetManager.set_level(_current_level)

	# SpawnPoint をレベルから読んで LoopManager に反映
	var spawn := _current_level.get_node_or_null("SpawnPoint")
	if spawn is Marker2D:
		LoopManager.base_spawn_position = spawn.global_position

	# Goal エリアにクリア検出を接続
	var goal := _current_level.get_node_or_null("Goal")
	if goal is Area2D:
		goal.body_entered.connect(func(_body): GameManager.end_play(true))

# ── 状態変化ハンドラ ──────────────────────────────────────────────────────────

func _on_state_changed(_state: int) -> void:
	pass  # HUD が処理

func _on_room_retried() -> void:
	# LoopManager / WorldResetManager はシグナルで自動リセット済み
	_load_level(initial_level)
	GameManager.start_game()  # → IDLE

func _on_next_stage_requested() -> void:
	# TODO: 次のレベルシーンをロード
	push_warning("次のステージ（未実装）")

func _on_return_to_title() -> void:
	# TODO: タイトルシーンへ遷移
	push_warning("タイトルへ（未実装）")
