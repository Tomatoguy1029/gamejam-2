extends CanvasLayer

@onready var _timer_label: Label = $MarginContainer/VBoxContainer/TopRow/TimerLabel
@onready var _loop_label: Label = $MarginContainer/VBoxContainer/TopRow/LoopLabel
@onready var _ghost_list: VBoxContainer = $MarginContainer/VBoxContainer/GhostList
@onready var _play_ended_panel: Control = $PlayEndedPanel
@onready var _clear_panel: Control = $ClearPanel
@onready var _idle_panel: Control = $IdlePanel

func _ready() -> void:
	$PlayEndedPanel/VBox/SaveButton.pressed.connect(_on_save_pressed)
	$PlayEndedPanel/VBox/DiscardButton.pressed.connect(_on_discard_pressed)
	$ClearPanel/VBox/NextStageButton.pressed.connect(GameManager.request_next_stage)
	$ClearPanel/VBox/TitleButton.pressed.connect(GameManager.request_return_to_title)

	GameManager.state_changed.connect(_on_state_changed)
	GameManager.ghost_saved.connect(_refresh_ghost_list)
	GameManager.ghost_discarded.connect(_refresh_ghost_list)
	GameManager.room_retried.connect(_refresh_ghost_list)

	_update_panels(GameManager.GameState.MAIN_MENU)

func _process(_delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_timer_label.text = "%.1f" % LoopManager.remaining_time_sec

func _on_state_changed(state: int) -> void:
	var gs := state as GameManager.GameState
	_update_panels(gs)
	if gs == GameManager.GameState.IDLE or gs == GameManager.GameState.PLAYING:
		_refresh_loop_label()

func _update_panels(state: GameManager.GameState) -> void:
	_idle_panel.visible = state == GameManager.GameState.IDLE
	_play_ended_panel.visible = (
		state == GameManager.GameState.PLAY_ENDED
		or state == GameManager.GameState.OVER_LIMIT
	)
	_clear_panel.visible = state == GameManager.GameState.CLEAR

func _refresh_loop_label() -> void:
	var remaining := LoopManager.max_ghosts - LoopManager.ghost_count
	_loop_label.text = "Loops: %d" % remaining

func _refresh_ghost_list() -> void:
	for child in _ghost_list.get_children():
		child.queue_free()

	for i in LoopManager.ghost_count:
		var ghost: GhostData = LoopManager.ghosts[i]
		var row := HBoxContainer.new()

		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = Vector2(20, 20)
		color_rect.color = ghost.color
		row.add_child(color_rect)

		var label := Label.new()
		label.text = "Ghost %d" % (i + 1)
		row.add_child(label)

		var btn := Button.new()
		btn.text = "×"
		var idx := i  # クロージャ用にコピー
		btn.pressed.connect(func(): _on_delete_ghost(idx))
		row.add_child(btn)

		_ghost_list.add_child(row)

	_refresh_loop_label()

func _on_save_pressed() -> void:
	var data := RecordingManager.build_ghost_data()
	LoopManager.add_ghost(data)
	GameManager.save_ghost()
	_refresh_ghost_list()

func _on_discard_pressed() -> void:
	GameManager.discard_ghost()

func _on_delete_ghost(index: int) -> void:
	LoopManager.remove_ghost(index)
	GameManager.continue_after_delete()
	_refresh_ghost_list()
