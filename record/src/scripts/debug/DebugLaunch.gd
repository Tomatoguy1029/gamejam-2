## デバッグ起動の指定を、エディタ（プラグイン）とゲーム本体の間で受け渡す。
##
## 受け渡しに user:// のファイルを使う理由：ProjectSettings の
## editor/run/main_run_args に起動引数を書く方法もあるが、それは project.godot を
## 書き換えるためコミットに乗ってしまう。user:// はエディタと実行中のゲームで
## 同じ場所（app_userdata/Record）に解決されるので、リポジトリを汚さずに済む。
##
## 予約（pending）は「1回だけ有効」。ゲーム側が起動時に読んだ直後 false に戻すため、
## その後の通常起動（F5）がデバッグ起動に化けることがない。これが
## 「F5 の挙動を変えない」を成立させている中心的な仕組み。
extends RefCounted

const PATH: String = "user://debug_launch.cfg"
const SECTION: String = "launch"
const LEVEL_DIR: String = "res://scenes/levels/"

## デバッグ起動を予約する（エディタ側から呼ぶ）。
static func request(stage_index: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)  # 既存の last_stage を残したいので、失敗しても続行する
	cfg.set_value(SECTION, "pending", true)
	cfg.set_value(SECTION, "stage", stage_index)
	cfg.set_value(SECTION, "last_stage", stage_index)
	cfg.save(PATH)

## 予約を読み取り、同時に消費する。予約が無ければ 0 を返す。
## ゲーム側の起動時に1度だけ呼ぶこと。
static func consume() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return 0
	if not bool(cfg.get_value(SECTION, "pending", false)):
		return 0
	var stage: int = int(cfg.get_value(SECTION, "stage", 0))
	cfg.set_value(SECTION, "pending", false)
	cfg.save(PATH)
	return stage

## 直近にデバッグ起動したステージ。記録が無ければ 0。
static func get_last_stage() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return 0
	return int(cfg.get_value(SECTION, "last_stage", 0))

## シーンのパスからステージ番号を得る。レベルシーンでなければ 0。
##   "res://scenes/levels/Level005.tscn" → 5
static func stage_index_from_path(scene_path: String) -> int:
	if not scene_path.begins_with(LEVEL_DIR):
		return 0
	var base: String = scene_path.get_file().get_basename()
	if not base.begins_with("Level"):
		return 0
	var num: String = base.trim_prefix("Level")
	if not num.is_valid_int():
		return 0
	return num.to_int()

## デバッグ起動の対象ステージを決める（spec 3.2 のフォールバック規則）。
##   レベルシーンを開いていればそれ → 直前にデバッグ起動したステージ → Stage 1
static func resolve_stage(edited_scene_path: String) -> int:
	var idx: int = stage_index_from_path(edited_scene_path)
	if idx > 0:
		return idx
	var last: int = get_last_stage()
	if last > 0:
		return last
	return 1

## 予約と記録を消す。テストと手動リセット用。
static func clear() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
