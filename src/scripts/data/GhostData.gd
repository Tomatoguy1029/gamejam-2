class_name GhostData
extends RefCounted

var ghost_index: int = 0
## Array[InputFrame]
var frames: Array = []
var color: Color = Color.WHITE

## 指定 tick の InputFrame を返す。範囲外は空フレーム。
func get_frame(tick: int) -> InputFrame:
	if tick < 0 or tick >= frames.size():
		var f := InputFrame.new()
		f.tick = tick
		return f
	return frames[tick]
