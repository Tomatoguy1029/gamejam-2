## 別プロセスから DebugLaunch.consume() を呼んで結果を出す補助スクリプト。
## test_debug_launch.gd が OS.execute() で起動し、user:// の受け渡しが
## プロセスをまたいで成立するか（spec の R-1）を確かめるために使う。
## Autoload を参照しないので --script モードで動く。
extends SceneTree

const DebugLaunch := preload("res://src/scripts/debug/DebugLaunch.gd")

func _initialize() -> void:
	print("CONSUMED=%d" % DebugLaunch.consume())
	quit(0)
