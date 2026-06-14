## CameraFrame のルート。録画の残り時間（タイマー）表示と、
## チュートリアルで習得した操作説明（Controls）の更新を担う。
## 角の枠・十字・REC・バッテリーは子ノードが担当。
extends Control

## 常に表示しておく操作説明（チュートリアル習得分の後ろに付く）。空なら無し。
@export var base_controls: String = "R: Retry"
## 全ステージ解放後（チュートリアル完了後）に固定表示する操作説明。
@export var fixed_controls: String = "WASD: Move   SPACE: Jump   R: Retry"

@onready var _timer_label: Label = $RecInfo/TimerLabel
@onready var _controls: Label = $Controls

## チュートリアル看板で習得した操作説明（重複なし・通過順）
var _hints: Array[String] = []

func _ready() -> void:
	GameManager.tutorial_hint.connect(_add_hint)
	GameManager.stages_unlocked.connect(_rebuild_controls)
	_rebuild_controls()

func _process(_delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_timer_label.text = "%.1f" % LoopManager.remaining_time_sec

func _add_hint(label: String) -> void:
	if label != "" and not _hints.has(label):
		_hints.append(label)
		_rebuild_controls()

func _rebuild_controls() -> void:
	# チュートリアル完了（全解放）後は固定表示
	if GameManager.all_stages_unlocked:
		_controls.text = fixed_controls
		return
	# チュートリアル中は看板で習得した分を表示
	var parts := _hints.duplicate()
	if base_controls != "":
		parts.append(base_controls)
	_controls.text = "   ".join(parts)
