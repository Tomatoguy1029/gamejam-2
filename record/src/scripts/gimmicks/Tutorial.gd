## チュートリアル看板ギミック。
## プレイヤーが範囲に入ると吹き出しを表示し、カメラフレームの操作説明UIに
## control_label を追加するシグナル(GameManager.tutorial_hint)を送る。
extends Area2D

## 吹き出しに表示する文章
@export var hint_text: String
@export var control_label: String

@onready var _bubble: Control = $Bubble
@onready var _label: Label = $Bubble/Label

func _ready() -> void:
	_label.text = hint_text
	_bubble.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	await get_tree().process_frame
	_bubble.pivot_offset = Vector2(_bubble.size.x * 0.5, _bubble.size.y)
	_bubble.scale = Vector2.ZERO

func _on_body_entered(_body: Node2D) -> void:
	_show_bubble()
	GameManager.tutorial_hint.emit(control_label)

func _on_body_exited(_body: Node2D) -> void:
	_hide_bubble()

func _show_bubble() -> void:
	_bubble.visible = true
	var tw := create_tween()
	tw.tween_property(_bubble, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hide_bubble() -> void:
	var tw := create_tween()
	tw.tween_property(_bubble, "scale", Vector2.ZERO, 0.12)
	await tw.finished
	_bubble.visible = false
