## テストのアサーションと集計。TestRunner が生成して各テストに渡す。
##
## class_name は付けない。グローバルクラスの登録はプロジェクト再スキャン後にしか
## 効かず、新規クローンや新しいファイルを足した直後の実行で解決に失敗するため。
## 利用側は `const TestAssert := preload("res://tests/Assert.gd")` で参照する。
extends RefCounted

var _file: String = ""
var _pass: int = 0
var _fail: int = 0
var _failures: Array[String] = []

func begin(file_name: String) -> void:
	_file = file_name
	print("\n-- %s --" % file_name)

## cond が true なら成功として数える。
func ok(label: String, cond: bool, detail: String = "") -> void:
	var suffix: String = "" if detail == "" else "  " + detail
	if cond:
		_pass += 1
		print("  [ OK ] %s%s" % [label, suffix])
	else:
		_fail += 1
		_failures.append("%s / %s%s" % [_file, label, suffix])
		print("  [FAIL] %s%s" % [label, suffix])

## actual == expected を確認する。失敗時に両方の値が出るよう detail に載せる。
func eq(label: String, actual: Variant, expected: Variant) -> void:
	ok(label, actual == expected, "actual=%s expected=%s" % [actual, expected])

## 最後に必ず呼ぶ。run_tests.sh はこの "TEST SUMMARY" 行の有無で
## 「最後まで走ったか」を判定するので、書式を変えないこと。
func report() -> void:
	print("\nTEST SUMMARY: pass %d / fail %d" % [_pass, _fail])
	for f in _failures:
		print("  FAILED: " + f)

## 各テストが最後に done() を呼んだか。TestRunner が「途中でスクリプトエラーが
## 起きて打ち切られた」を検出するのに使う。GDScript の実行時エラーは例外にならず
## その場で関数を抜けるだけなので、完走マーカーが無いと失敗を見逃す。
var _done: bool = false

## 各テストの run_tests() の最後で必ず呼ぶ。
func done() -> void:
	_done = true

func is_done() -> bool:
	return _done

func reset_done() -> void:
	_done = false

func exit_code() -> int:
	return 0 if _fail == 0 else 1
