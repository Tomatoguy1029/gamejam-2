## ツールバーに「▶ Debug」ボタンを足すエディタプラグイン。
##
## 押すと「いま編集しているレベル」を起動対象として予約し、通常どおり
## メインシーンを実行する。予約はゲーム側が起動時に1回だけ消費するので、
## F5（通常実行）はこれまでどおりタイトルから始まる。
##
## 起動対象の決め方は DebugLaunch.resolve_stage() に置いてある。
## レベル以外のシーンを開いていれば直前のステージ、それも無ければ Stage 1。
@tool
extends EditorPlugin

const DebugLaunch := preload("res://src/scripts/debug/DebugLaunch.gd")

var _button: Button = null

func _enter_tree() -> void:
	_button = Button.new()
	_button.text = "▶ Debug"
	_button.tooltip_text = "編集中のステージを直接起動する（F5 は通常どおりタイトルから）"
	_button.pressed.connect(_on_pressed)
	add_control_to_container(CONTAINER_TOOLBAR, _button)

func _exit_tree() -> void:
	if _button != null:
		remove_control_from_container(CONTAINER_TOOLBAR, _button)
		_button.queue_free()
		_button = null

func _on_pressed() -> void:
	DebugLaunch.request(DebugLaunch.resolve_stage(_current_scene_path()))
	EditorInterface.play_main_scene()

## 編集中のシーンのパス。保存できるものは先に保存する。
## 起動するのは保存済みの内容なので、保存しないと画面と食い違うため。
## 未保存の新規シーンは scene_file_path が空になるので、保存はせず空を返す
## （DebugLaunch 側のフォールバックに任せる）。
func _current_scene_path() -> String:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root == null:
		return ""
	if root.scene_file_path == "":
		return ""
	EditorInterface.save_scene()
	return root.scene_file_path
