## デバッグメニューの項目（ステージ移動 / ゴースト数）のテスト。
## Main ごと立ち上げて、実際に画面が切り替わるところまで確かめる。
extends Node

const TestAssert := preload("res://tests/Assert.gd")
const DebugLaunch := preload("res://src/scripts/debug/DebugLaunch.gd")
const MAIN := preload("res://scenes/Main.tscn")

func run_tests(t: TestAssert) -> void:
	DebugLaunch.request(1)
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	var menu: CanvasLayer = main.get_node("DebugMenu")
	var items: VBoxContainer = menu.get_node("Panel/Scroll/Items")

	# ── ステージ移動 ──────────────────────────────────────
	t.eq("デバッグ起動で Stage 1 から始まる", main._current_level_index, 1)
	t.ok("ステージ一覧が項目に並ぶ",
		_find_button(items, "Stage 1") != null and _find_button(items, "Stage 5") != null)

	menu.set_open(true)
	_find_button(items, "Stage 3").pressed.emit()
	await get_tree().process_frame
	t.eq("メニューからステージを移動できる", main._current_level_index, 3)
	t.ok("Level003 が読み込まれている",
		main._current_level != null and main._current_level.name == "Level003",
		"level=%s" % [main._current_level])
	t.ok("移動したらメニューは閉じる", not menu.is_open)
	t.ok("移動後は入力ロックが解除される", not GameManager.input_locked)

	main.queue_free()
	await get_tree().process_frame
	GameManager.current_state = GameManager.GameState.MAIN_MENU
	LoopManager.ClearAll()
	LoopManager.set_spawn_parent(null)
	WorldResetManager.set_level(null)
	GameManager.input_locked = false
	DebugLaunch.clear()
	await get_tree().process_frame

func _find_button(root: Node, text: String) -> Button:
	for child in root.get_children():
		if child is Button and (child as Button).text == text:
			return child
		var found: Button = _find_button(child, text)
		if found != null:
			return found
	return null
