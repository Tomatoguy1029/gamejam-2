## デバッグメニューの開閉と登録 API のテスト。
extends Node

const TestAssert := preload("res://tests/Assert.gd")
const MENU := preload("res://scenes/ui/DebugMenu.tscn")

func run_tests(t: TestAssert) -> void:
	GameManager.input_locked = false
	var menu: CanvasLayer = MENU.instantiate()
	add_child(menu)
	await get_tree().process_frame

	t.ok("エディタ実行なら有効", menu.is_available())
	t.ok("初期状態は閉じている", not menu.is_open)
	t.ok("閉じている間は入力ロックしない", not GameManager.input_locked)

	# ── 開閉と入力ロック ──────────────────────────────────
	menu.toggle()
	t.ok("toggle() で開く", menu.is_open)
	t.ok("開いている間はゲーム操作を止める", GameManager.input_locked)
	menu.toggle()
	t.ok("もう一度 toggle() で閉じる", not menu.is_open)
	t.ok("閉じたら入力ロックを解除する", not GameManager.input_locked)

	# ── 既定のショートカット（Esc）で開閉できる ────────────
	t.ok("既定のショートカットが割り当てられている",
		menu.toggle_menu_shortcut != null and menu.toggle_menu_shortcut.has_valid_event())
	await _press_key(KEY_ESCAPE)
	t.ok("Esc で開く", menu.is_open)
	await _press_key(KEY_ESCAPE)
	t.ok("Esc で閉じる", not menu.is_open)

	# ── R-2: 他が入力をロックしている間は開かない ──────────
	GameManager.input_locked = true
	await _press_key(KEY_ESCAPE)
	t.ok("演出中（入力ロック中）は開かない", not menu.is_open)
	t.ok("ロックを横取りしない", GameManager.input_locked)
	GameManager.input_locked = false

	# ── ショートカットは差し替えられる ─────────────────────
	menu.toggle_menu_shortcut = _shortcut(KEY_F9)
	menu.refresh_shortcuts()
	await _press_key(KEY_F9)
	t.ok("割り当てを変えたキーで開く", menu.is_open)
	await _press_key(KEY_F9)
	t.ok("同じキーで閉じる", not menu.is_open)
	await _press_key(KEY_ESCAPE)
	t.ok("差し替え前のキーは効かなくなる", not menu.is_open)

	# ── 未割り当てならキーでは開かない ─────────────────────
	menu.toggle_menu_shortcut = null
	menu.refresh_shortcuts()
	await _press_key(KEY_ESCAPE)
	await _press_key(KEY_F9)
	t.ok("未割り当てならキーでは開かない", not menu.is_open)
	t.ok("それでも toggle() では開ける", _open_via_call(menu))
	menu.set_open(false)

	# ── 登録 API ─────────────────────────────────────────
	var items: VBoxContainer = menu.get_node("Panel/Scroll/Items")
	var before: int = items.get_child_count()

	var flag := {"n": 0}
	var row: Control = menu._add_action("押す", func() -> void: flag["n"] += 1)
	t.ok("_add_action が項目を増やす", items.get_child_count() > before)
	_find_button(row, "押す").pressed.emit()
	t.eq("_add_action のボタンが呼ばれる", flag["n"], 1)

	var num := {"v": 2}
	row = menu._add_int("数値", func() -> int: return num["v"],
		func(v: int) -> void: num["v"] = v, 0, 3)
	_find_button(row, "＋").pressed.emit()
	t.eq("_add_int の ＋ が setter を呼ぶ", num["v"], 3)
	_find_button(row, "＋").pressed.emit()
	t.eq("_add_int は上限でクランプする", num["v"], 3)
	_find_button(row, "−").pressed.emit()
	t.eq("_add_int の − が setter を呼ぶ", num["v"], 2)

	var onoff := {"v": false}
	row = menu._add_bool("フラグ", func() -> bool: return onoff["v"],
		func(v: bool) -> void: onoff["v"] = v)
	_find_check(row).button_pressed = true
	t.ok("_add_bool が setter を呼ぶ", onoff["v"])

	var picked := {"i": -1}
	row = menu._add_list("一覧", PackedStringArray(["A", "B", "C"]),
		func(i: int) -> void: picked["i"] = i)
	_find_button(row, "C").pressed.emit()
	t.eq("_add_list が選んだ位置を渡す", picked["i"], 2)

	var info := {"v": "old"}
	row = menu._add_info("表示", func() -> String: return info["v"])
	info["v"] = "new"
	menu.set_open(true)
	t.eq("_add_info は開くたびに再評価される", _find_label(row, "new") != null, true)
	menu.set_open(false)

	# ── 見た目：パネルは内容の高さに収まる（画面を覆わない）──
	var panel: Control = menu.get_node("Panel")
	menu.set_open(true)
	await get_tree().process_frame
	t.ok("パネルが画面の高さを覆わない", panel.size.y < 1080.0,
		"panel=%s" % [panel.size])

	# ── 見た目：一覧が増えても見切れず折り返す ────────────
	var many := PackedStringArray()
	for i in 12:
		many.append("Stage %d" % (i + 1))
	menu._add_list("多数", many, func(_i: int) -> void: pass)
	await menu._fit_panel()
	await get_tree().process_frame

	var panel_right: float = panel.global_position.x + panel.size.x
	var overflow: int = 0
	var rows := {}
	for node in _walk(panel):
		if node is Button and (node as Button).text.begins_with("Stage "):
			var button := node as Button
			if button.global_position.x + button.size.x > panel_right:
				overflow += 1
			rows[button.global_position.y] = true
	t.eq("ボタンがパネルからはみ出さない", overflow, 0)
	t.ok("12個並べたら複数行に折り返す", rows.size() > 1, "行数=%d" % rows.size())

	menu.set_open(false)
	menu.queue_free()
	GameManager.input_locked = false
	await get_tree().process_frame
	t.done()

func _press_key(key: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame

## 指定キー1つだけの Shortcut を作る。
func _shortcut(key: Key) -> Shortcut:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	var sc := Shortcut.new()
	sc.events = [ev]
	return sc

func _open_via_call(menu: CanvasLayer) -> bool:
	menu.toggle()
	return menu.is_open

func _find_button(root: Node, text: String) -> Button:
	for n in _walk(root):
		if n is Button and (n as Button).text == text:
			return n
	return null

func _find_check(root: Node) -> CheckBox:
	for n in _walk(root):
		if n is CheckBox:
			return n
	return null

func _find_label(root: Node, text: String) -> Label:
	for n in _walk(root):
		if n is Label and (n as Label).text == text:
			return n
	return null

func _walk(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in root.get_children():
		out.append(child)
		out.append_array(_walk(child))
	return out
