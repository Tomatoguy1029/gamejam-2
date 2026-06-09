class_name InputFrame
extends RefCounted

var tick: int = 0
var move_dir: float = 0.0
var jump: bool = false
var interact: bool = false
var move_up: bool = false
var move_down: bool = false

static func create(t: int, md: float, j: bool, i: bool, mu: bool, mdown: bool) -> InputFrame:
	var f := InputFrame.new()
	f.tick = t
	f.move_dir = md
	f.jump = j
	f.interact = i
	f.move_up = mu
	f.move_down = mdown
	return f
