## タイトル画面 + ステージ選択UI。GameState.MAIN_MENU のときに表示。
extends CanvasLayer

const STAGE_NAME_FONT_SIZE := 40

signal stage_selected(level_index: int)

@onready var _stage_list: VBoxContainer = $Panel/VBoxContainer/StageList

func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)
	_build_stage_list()
	visible = GameManager.current_state == GameManager.GameState.MAIN_MENU

func _on_state_changed(state: int) -> void:
	visible = state == GameManager.GameState.MAIN_MENU
	if visible:
		_build_stage_list()

func _build_stage_list() -> void:
	for child in _stage_list.get_children():
		child.queue_free()

	var dir := DirAccess.open("res://scenes/levels/")
	if dir == null:
		return

	var files: Array[String] = []
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.begins_with("Level") and f.ends_with(".tscn"):
			files.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	files.sort()

	for file_name in files:
		# "Level001.tscn" → index = 1
		var num_str := file_name.trim_prefix("Level").trim_suffix(".tscn")
		var index := num_str.to_int()

		var btn := Button.new()
		btn.text = "Stage %d" % index
		btn.add_theme_font_size_override("font_size", STAGE_NAME_FONT_SIZE)
		btn.custom_minimum_size = Vector2(300, 60)
		btn.pressed.connect(func(): stage_selected.emit(index))
		_stage_list.add_child(btn)
