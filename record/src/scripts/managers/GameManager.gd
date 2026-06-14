## ゲーム全体の状態機械。Autoload として登録。
## 状態遷移とシグナル発火のみを担う。
extends Node

enum GameState {
	MAIN_MENU,
	IDLE,        # ループ開始待ち（Space 待ち）
	PLAYING,     # 録画中・ゴースト再生中
	PLAY_ENDED,  # 保存 or 破棄 選択中
	OVER_LIMIT,  # ゴースト枠が埋まった・未クリア
	CLEAR,
	ROOM_RETRY,
}

signal state_changed(new_state: int)
signal loop_started(loop_index: int)
signal play_ended(reached_goal: bool)
signal ghost_saved()
signal ghost_discarded()
signal over_limit()
signal room_retried()
signal cleared()
signal next_stage_requested()
signal return_to_title_requested()

var current_state: GameState = GameState.MAIN_MENU

var input_locked: bool = false

# ── 状態遷移 API ────────────────────────────────────────────────────────────

func start_game() -> void:
	_change_state(GameState.IDLE)

func start_loop(loop_index: int) -> void:
	_change_state(GameState.PLAYING)
	loop_started.emit(loop_index)

func end_play(reached_goal: bool) -> void:
	if reached_goal:
		_change_state(GameState.CLEAR)
		cleared.emit()
	else:
		_change_state(GameState.PLAY_ENDED)
		play_ended.emit(false)

func save_ghost() -> void:
	ghost_saved.emit()
	_change_state(GameState.IDLE)

func discard_ghost() -> void:
	ghost_discarded.emit()
	_change_state(GameState.IDLE)

func trigger_over_limit() -> void:
	over_limit.emit()
	_change_state(GameState.OVER_LIMIT)

## OverLimit 状態でゴーストを削除後、次ループへ続行
func continue_after_delete() -> void:
	_change_state(GameState.IDLE)

func room_retry() -> void:
	_change_state(GameState.ROOM_RETRY)
	room_retried.emit()

func request_next_stage() -> void:
	next_stage_requested.emit()

func request_return_to_title() -> void:
	_change_state(GameState.MAIN_MENU)
	return_to_title_requested.emit()

## 外部から直接状態を変えたい場合（LoopManager など）
func change_state(next: GameState) -> void:
	_change_state(next)

func _change_state(next: GameState) -> void:
	current_state = next
	state_changed.emit(int(next))
