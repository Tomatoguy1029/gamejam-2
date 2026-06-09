## プレイヤー操作を受け付ける ActorBase サブクラス。
## キーボード入力を Dictionary に変換し、RecordingManager へ記録を依頼する。
extends "res://src/scripts/actors/ActorBase.gd"

var _loop_tick: int = 0

func _ready() -> void:
	GameManager.loop_started.connect(func(_idx): _loop_tick = 0)

func _physics_process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		RecordingManager.record_frame(_sample_input_frame())
		_loop_tick += 1

		if Input.is_action_just_pressed("retry"):
			GameManager.end_play(false)

	# K / L キーは PlayEnded 状態でのみ有効
	if GameManager.current_state == GameManager.GameState.PLAY_ENDED:
		if Input.is_action_just_pressed("save_ghost"):
			var data := RecordingManager.build_ghost_data()
			LoopManager.add_ghost(data)
			GameManager.save_ghost()
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

func _sample_input_frame() -> InputFrame:
	return InputFrame.create(
		_loop_tick,
		Input.get_axis("move_left", "move_right"),
		Input.is_action_just_pressed("jump"),
		Input.is_action_pressed("interact"),
		Input.is_action_pressed("move_up"),
		Input.is_action_pressed("move_down"),
	)
