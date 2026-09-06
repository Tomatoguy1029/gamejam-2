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

	# ── ゴースト数 ────────────────────────────────────────
	menu.set_open(true)
	t.eq("初期値はステージの max_ghosts（Level003 は 2）", LoopManager.max_ghosts, 2)
	_find_button(items, "＋").pressed.emit()
	t.eq("＋ で増える", LoopManager.max_ghosts, 3)
	_find_button(items, "−").pressed.emit()
	_find_button(items, "−").pressed.emit()
	t.eq("− で減る", LoopManager.max_ghosts, 1)
	_find_button(items, "−").pressed.emit()
	t.eq("下限 0 でクランプする", LoopManager.max_ghosts, 0)

	# ── R-3: 保存済み本数より小さくしても HUD が壊れないか ──
	LoopManager.max_ghosts = 3
	LoopManager.add_ghost(GhostData.new())
	LoopManager.add_ghost(GhostData.new())
	t.eq("ゴーストを2本保存した状態にする", LoopManager.ghost_count, 2)
	_find_button(items, "−").pressed.emit()
	_find_button(items, "−").pressed.emit()
	t.eq("保存済みより小さい上限にできる", LoopManager.max_ghosts, 1)
	t.ok("上限に達した扱いになる", LoopManager.is_at_limit)

	GameManager.change_state(GameManager.GameState.PLAY_ENDED)
	await get_tree().process_frame
	var icons: HBoxContainer = main.get_node("HUD/PlayEndedPanel/VBox/GhostIcons")
	t.eq("HUD のスロットは上限ぶんだけ並ぶ（保存済み2 > 上限1 でも壊れない）",
		icons.get_child_count(), 1)

	# ── 状態表示 ──────────────────────────────────────────
	GameManager.change_state(GameManager.GameState.IDLE)
	menu.set_open(true)
	t.ok("現在のステージが表示される", _find_label(items, "Level003") != null)
	t.ok("保存済みゴーストが 本数/上限 で表示される",
		_find_label(items, "%d / %d" % [LoopManager.ghost_count, LoopManager.max_ghosts]) != null)
	t.ok("GameState が名前で表示される", _find_label(items, "IDLE") != null)
	menu.set_open(false)

	main.queue_free()
	await get_tree().process_frame
	GameManager.current_state = GameManager.GameState.MAIN_MENU
	LoopManager.ClearAll()
	LoopManager.set_spawn_parent(null)
	WorldResetManager.set_level(null)
	GameManager.input_locked = false
	DebugLaunch.clear()
	await get_tree().process_frame
	t.done()

func _find_button(root: Node, text: String) -> Button:
	for child in root.get_children():
		if child is Button and (child as Button).text == text:
			return child
		var found: Button = _find_button(child, text)
		if found != null:
			return found
	return null

func _find_label(root: Node, text: String) -> Label:
	for child in root.get_children():
		if child is Label and (child as Label).text == text:
			return child
		var found: Label = _find_label(child, text)
		if found != null:
			return found
	return null
