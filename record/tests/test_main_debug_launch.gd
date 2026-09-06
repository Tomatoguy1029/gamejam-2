## Main の起動分岐のテスト。
## 「予約があればそのステージへ直行」「無ければタイトルのまま（F5 の挙動）」を確かめる。
extends Node

const TestAssert := preload("res://tests/Assert.gd")
const DebugLaunch := preload("res://src/scripts/debug/DebugLaunch.gd")
const MAIN := preload("res://scenes/Main.tscn")

func run_tests(t: TestAssert) -> void:
	# ── 予約なし ＝ 通常の F5。タイトルのまま ────────────────
	DebugLaunch.clear()
	GameManager.all_stages_unlocked = false
	var main: Node2D = await _spawn()
	t.eq("予約なしならタイトル（F5 の挙動を変えない）",
		GameManager.current_state, GameManager.GameState.MAIN_MENU)
	t.ok("レベルは読み込まれない", main._current_level == null)
	var menu: Node = main.get_node_or_null("DebugMenu")
	t.ok("Main にデバッグメニューがぶら下がっている", menu != null)
	t.ok("デバッグメニューは閉じた状態で始まる", menu != null and not menu.is_open)
	await _despawn(main)

	# ── 予約あり ＝ そのステージへ直行 ──────────────────────
	DebugLaunch.request(2)
	GameManager.all_stages_unlocked = false
	main = await _spawn()
	t.eq("予約したステージへ直行して IDLE",
		GameManager.current_state, GameManager.GameState.IDLE)
	t.ok("Level002 が読み込まれている",
		main._current_level != null and main._current_level.name == "Level002",
		"level=%s" % [main._current_level])
	t.eq("ステージ番号が一致する", main._current_level_index, 2)
	t.ok("全ステージ解放になる（メニューから飛べるように）", GameManager.all_stages_unlocked)
	t.eq("予約は消費済み", DebugLaunch.consume(), 0)
	await _despawn(main)

	# ── 予約は1回きり。次の起動はタイトルに戻る ───────────────
	main = await _spawn()
	t.eq("2回目の起動はタイトル（予約が残らない）",
		GameManager.current_state, GameManager.GameState.MAIN_MENU)
	await _despawn(main)

	# ── 存在しないステージを予約したらタイトルへ退避 ──────────
	DebugLaunch.request(999)
	main = await _spawn()
	t.eq("存在しないステージならタイトルへ",
		GameManager.current_state, GameManager.GameState.MAIN_MENU)
	await _despawn(main)

	DebugLaunch.clear()
	t.done()

func _spawn() -> Node2D:
	var main: Node2D = MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	return main

func _despawn(main: Node2D) -> void:
	main.queue_free()
	await get_tree().process_frame
	# Autoload はテスト間で生き続けるので、次のテストに状態を持ち越さない
	GameManager.current_state = GameManager.GameState.MAIN_MENU
	LoopManager.ClearAll()
	LoopManager.set_spawn_parent(null)
	WorldResetManager.set_level(null)
	await get_tree().process_frame
