## ゲームシーンのルートスクリプト。
## Manager 群の接続・レベルロード・ゲームフロー全体を仲介する。
extends Node2D

var _current_level: Node2D = null
var _current_level_index: int = 1

func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.room_retried.connect(_on_room_retried)
	GameManager.next_stage_requested.connect(_on_next_stage_requested)
	GameManager.return_to_title_requested.connect(_on_return_to_title)

	# StageSelect のシグナルを接続
	var stage_select := $StageSelect
	stage_select.stage_selected.connect(_on_stage_selected)

	# タイトル画面から開始
	GameManager.change_state(GameManager.GameState.MAIN_MENU)

func _unhandled_input(_event: InputEvent) -> void:
	if GameManager.input_locked:
		return
	if GameManager.current_state == GameManager.GameState.IDLE:
		if Input.is_action_just_pressed("jump"):
			_start_loop()

# ── ループ開始 ────────────────────────────────────────────────────────────────

func _start_loop() -> void:
	GameManager.start_loop(LoopManager.current_loop_index)

# ── レベル管理 ────────────────────────────────────────────────────────────────

func _load_level_by_index(index: int) -> bool:
	var path := "res://scenes/levels/Level%03d.tscn" % index
	if not ResourceLoader.exists(path):
		return false

	if is_instance_valid(_current_level):
		_current_level.queue_free()

	_current_level = load(path).instantiate()
	add_child(_current_level)
	move_child(_current_level, 0)

	# ステージ固有の最大ゴースト数を反映
	if _current_level is Level:
		LoopManager.max_ghosts = _current_level.max_ghosts

	# IDLE 入り（start_game）時にアクター配置されるので、先に配置先を渡しておく
	LoopManager.set_spawn_parent(_current_level)
	WorldResetManager.set_level(_current_level)

	var spawn := _current_level.get_node_or_null("SpawnPoint")
	if spawn is Marker2D:
		LoopManager.base_spawn_position = spawn.global_position

	var goal := _current_level.get_node_or_null("Goal")
	if goal is Area2D:
		goal.body_entered.connect(func(_body): GameManager.end_play(true))

	return true

# ── 状態変化ハンドラ ──────────────────────────────────────────────────────────

func _on_state_changed(_state: int) -> void:
	pass

func _on_stage_selected(index: int) -> void:
	_current_level_index = index
	LoopManager.ClearAll()
	if _load_level_by_index(index):
		GameManager.start_game()  # → IDLE

func _on_room_retried() -> void:
	LoopManager.ClearAll()
	_load_level_by_index(_current_level_index)
	GameManager.start_game()

func _on_next_stage_requested() -> void:
	var next := _current_level_index + 1
	LoopManager.ClearAll()
	if _load_level_by_index(next):
		_current_level_index = next
		GameManager.start_game()
	else:
		# 次のステージがなければタイトルへ
		GameManager.request_return_to_title()

func _on_return_to_title() -> void:
	if is_instance_valid(_current_level):
		_current_level.queue_free()
		_current_level = null
	LoopManager.ClearAll()
