## プレイヤー操作を受け付ける ActorBase サブクラス。
## キーボード入力を Dictionary に変換し、RecordingManager へ記録を依頼する。
extends "res://src/scripts/actors/ActorBase.gd"

var _loop_tick: int = 0

## 逆再生（巻き戻し演出）用の軌跡。数フレームごとに座標を記録する。
const TRAIL_INTERVAL := 4      # 何物理フレームごとに座標を記録するか
const REWIND_DURATION := 3.0   # 逆再生アニメの総尺（秒・固定）
var _trail: PackedVector2Array = []

func _ready() -> void:
	GameManager.loop_started.connect(func(_idx):
		_loop_tick = 0
		_trail.clear()
	)

func _physics_process(delta: float) -> void:
	# 入力ロック中は操作・録画・各キーを受け付けない
	if GameManager.input_locked:
		super._physics_process(delta)
		return

	if GameManager.current_state == GameManager.GameState.PLAYING:
		RecordingManager.record_frame(_sample_input_frame())
		if _loop_tick % TRAIL_INTERVAL == 0:
			_trail.append(global_position)
		_loop_tick += 1

		if Input.is_action_just_pressed("retry"):
			GameManager.end_play(false)

	if (GameManager.current_state == GameManager.GameState.PLAY_ENDED
			or GameManager.current_state == GameManager.GameState.OVER_LIMIT):
		if Input.is_action_just_pressed("save_ghost"):
			LoopManager.save_recording(RecordingManager.build_ghost_data())
		elif Input.is_action_just_pressed("discard_ghost"):
			GameManager.discard_ghost()

	super._physics_process(delta)

func _get_input() -> Dictionary:
	return {
		move_dir = Input.get_axis("move_left", "move_right"),
		jump = Input.is_action_just_pressed("jump"),
		interact = Input.is_action_pressed("interact"),
		move_up = Input.is_action_pressed("move_up"),
		move_down = Input.is_action_pressed("move_down"),
	}

## 記録した軌跡を逆順に辿る巻き戻しアニメ。総尺は REWIND_DURATION に固定し、
## 1区間の時間 = 尺 / (点数 - 1) として点数に依らず尺に収める。完了まで await 可能。
func rewind() -> void:
	if _trail.size() < 2:
		return
	var count: int = _trail.size()
	var step: float = REWIND_DURATION / float(count - 1)
	var tw := create_tween()
	for i in range(count - 2, -1, -1):
		tw.tween_property(self, "global_position", _trail[i], step)
	await tw.finished

func _sample_input_frame() -> InputFrame:
	return InputFrame.create(
		_loop_tick,
		Input.get_axis("move_left", "move_right"),
		Input.is_action_just_pressed("jump"),
		Input.is_action_pressed("interact"),
		Input.is_action_pressed("move_up"),
		Input.is_action_pressed("move_down"),
	)
