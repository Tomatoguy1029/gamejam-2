extends CanvasLayer

const GHOST_ROW_COLOR_SIZE := Vector2(80, 80)
const GHOST_ROW_FONT_SIZE := 55
const GHOST_ROW_BTN_FONT_SIZE := 50

@onready var _timer_label: Label = $MarginContainer/VBoxContainer/TopRow/TimerLabel
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
	GameManager.return_to_title_requested.connect(_refresh_ghost_list)

	_update_panels(GameManager.GameState.MAIN_MENU)

func _process(_delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_timer_label.text = "%.1f" % LoopManager.remaining_time_sec

func _on_state_changed(state: int) -> void:
	_update_panels(state as GameManager.GameState)

func _update_panels(state: GameManager.GameState) -> void:
	_idle_panel.visible = state == GameManager.GameState.IDLE
	_play_ended_panel.visible = (
		state == GameManager.GameState.PLAY_ENDED
		or state == GameManager.GameState.OVER_LIMIT
	)
	_clear_panel.visible = state == GameManager.GameState.CLEAR

func _refresh_ghost_list() -> void:
	for child in _ghost_list.get_children():
		child.queue_free()

	for i in LoopManager.ghost_count:
		var ghost: GhostData = LoopManager.ghosts[i]
		var row := HBoxContainer.new()

		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = GHOST_ROW_COLOR_SIZE
		color_rect.color = ghost.color
		row.add_child(color_rect)

		var label := Label.new()
		label.text = "Ghost %d" % (i + 1)
		label.add_theme_font_size_override("font_size", GHOST_ROW_FONT_SIZE)
		row.add_child(label)

		var btn := Button.new()
		btn.text = "×"
		btn.add_theme_font_size_override("font_size", GHOST_ROW_BTN_FONT_SIZE)
		var idx := i
		btn.pressed.connect(func(): _on_delete_ghost(idx))
		row.add_child(btn)

		_ghost_list.add_child(row)

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
