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

	# ── F3 キーで開閉できる ───────────────────────────────
	await _press_f3()
	t.ok("F3 で開く", menu.is_open)
	await _press_f3()
	t.ok("F3 で閉じる", not menu.is_open)

	# ── R-2: 他が入力をロックしている間は開かない ──────────
	GameManager.input_locked = true
	await _press_f3()
	t.ok("演出中（入力ロック中）は F3 で開かない", not menu.is_open)
	t.ok("ロックを横取りしない", GameManager.input_locked)
	GameManager.input_locked = false

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

	menu.queue_free()
	GameManager.input_locked = false
	await get_tree().process_frame
	t.done()

func _press_f3() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_F3
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame

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
