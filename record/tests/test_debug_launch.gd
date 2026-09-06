## デバッグ起動の受け渡し（DebugLaunch）のテスト。
extends Node

const TestAssert := preload("res://tests/Assert.gd")
const DebugLaunch := preload("res://src/scripts/debug/DebugLaunch.gd")

func run_tests(t: TestAssert) -> void:
	DebugLaunch.clear()

	# ── 予約と消費 ────────────────────────────────────────
	t.eq("予約が無ければ 0", DebugLaunch.consume(), 0)
	DebugLaunch.request(3)
	t.eq("予約したステージが読める", DebugLaunch.consume(), 3)
	t.eq("2回目は 0（通常の F5 に漏れない）", DebugLaunch.consume(), 0)
	t.eq("last_stage は消費後も残る", DebugLaunch.get_last_stage(), 3)

	# ── シーンパス → ステージ番号 ─────────────────────────
	t.eq("レベルのパスから番号を取る",
		DebugLaunch.stage_index_from_path("res://scenes/levels/Level005.tscn"), 5)
	t.eq("レベル以外は 0",
		DebugLaunch.stage_index_from_path("res://scenes/gimmicks/Pulley.tscn"), 0)
	t.eq("空パスは 0", DebugLaunch.stage_index_from_path(""), 0)

	# ── フォールバック規則（spec 3.2）────────────────────
	t.eq("レベルを開いていればそのステージ",
		DebugLaunch.resolve_stage("res://scenes/levels/Level002.tscn"), 2)
	t.eq("レベル以外なら直前のステージ",
		DebugLaunch.resolve_stage("res://scenes/gimmicks/Pulley.tscn"), 3)
	DebugLaunch.clear()
	t.eq("直前の記録も無ければ Stage 1", DebugLaunch.resolve_stage(""), 1)

	# ── R-1: 別プロセス間で受け渡せるか ───────────────────
	DebugLaunch.request(4)
	var out: Array = []
	var code: int = OS.execute(OS.get_executable_path(), [
		"--headless",
		"--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/helpers/print_launch.gd",
	], out, true)
	var text: String = ""
	for chunk in out:
		text += str(chunk)
	t.ok("別プロセスが予約を読める（R-1）", text.contains("CONSUMED=4"),
		"exit=%d" % code)
	t.eq("別プロセスの消費が親側にも反映される（R-1）", DebugLaunch.consume(), 0)

	DebugLaunch.clear()
	t.done()
