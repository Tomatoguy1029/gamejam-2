## res://tests/ 以下の test_*.gd を集めて順に実行する。
##
## --script ではなくシーンとして起動する。Autoload（GameManager 等）は
## カスタム MainLoop では登録されず、参照するテストがコンパイルに失敗するため。
##
##   ./run_tests.sh
##
## 各テストは Node を継承し、`func run_tests(t: TestAssert) -> void:` を実装する。
## 物理フレームを進めたいテストは await してよい。
extends Node

const TestAssert := preload("res://tests/Assert.gd")

func _ready() -> void:
	var t := TestAssert.new()
	for path in _discover():
		var script: Variant = load(path)
		if script == null:
			t.begin(path.get_file())
			t.ok("スクリプトが読み込めること", false, path)
			continue
		var node := Node.new()
		node.set_script(script)
		add_child(node)
		t.begin(path.get_file())
		if node.has_method("run_tests"):
			await node.run_tests(t)
		else:
			t.ok("run_tests() が実装されていること", false, path)
		node.queue_free()
	t.report()
	get_tree().quit(t.exit_code())

func _discover() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open("res://tests/")
	if dir == null:
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.begins_with("test_") and f.ends_with(".gd"):
			out.append("res://tests/" + f)
		f = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out
