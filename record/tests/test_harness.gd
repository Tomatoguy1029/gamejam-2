## ハーネス自身の自己確認。発見・実行・await・集計が動くことを確かめる。
extends Node

const TestAssert := preload("res://tests/Assert.gd")

func run_tests(t: TestAssert) -> void:
	t.ok("ok() が成功を数える", true)
	t.eq("eq() が値を比較できる", 1 + 1, 2)
	await get_tree().physics_frame
	t.ok("await のあとも継続できる", true)
