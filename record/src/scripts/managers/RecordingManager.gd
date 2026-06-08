## Playing 中にプレイヤー入力を毎物理フレーム記録し、GhostData を生成する。Autoload。
extends Node

## Array[InputFrame]
var _frames: Array = []
var _recording: bool = false

func _ready() -> void:
	GameManager.loop_started.connect(func(_idx): start_recording())
	GameManager.play_ended.connect(func(_reached): stop_recording())
	GameManager.cleared.connect(stop_recording)

func start_recording() -> void:
	_frames.clear()
	_recording = true

func stop_recording() -> void:
	_recording = false

## PlayerController から毎物理フレーム呼ばれる。
func record_frame(frame: InputFrame) -> void:
	if not _recording:
		return
	_frames.append(frame)

## 録画を確定して GhostData を返す。
## ghost_index / color は LoopManager.add_ghost() 内で設定される。
func build_ghost_data() -> GhostData:
	var data := GhostData.new()
	data.frames = _frames.duplicate()
	return data
