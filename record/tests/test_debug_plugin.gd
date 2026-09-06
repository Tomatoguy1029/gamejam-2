## エディタプラグインの配線のテスト。
## プラグイン本体はエディタ上でしか動かせないので、ここでは
## 「解析できる」「定義が揃っている」「有効化されている」までを確認する。
extends Node

const TestAssert := preload("res://tests/Assert.gd")
const PLUGIN_CFG := "res://addons/debug_launcher/plugin.cfg"

func run_tests(t: TestAssert) -> void:
	# エディタで開いた瞬間にパースエラーにならないこと
	var script: Variant = load("res://addons/debug_launcher/plugin.gd")
	t.ok("plugin.gd が読み込める", script != null)

	var cfg := ConfigFile.new()
	t.eq("plugin.cfg が読める", cfg.load(PLUGIN_CFG), OK)
	t.eq("script キーが plugin.gd を指す", str(cfg.get_value("plugin", "script", "")), "plugin.gd")
	t.ok("name が入っている", str(cfg.get_value("plugin", "name", "")) != "")

	var enabled: PackedStringArray = ProjectSettings.get_setting(
		"editor_plugins/enabled", PackedStringArray())
	t.ok("project.godot でプラグインが有効化されている",
		Array(enabled).has(PLUGIN_CFG), str(enabled))

	t.done()
