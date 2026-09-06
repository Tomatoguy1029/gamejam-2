## 梯子ギミック。
## 複数重ねても正しく動くようカウンターで管理する。
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if "_ladder_count" in body:
		body._ladder_count += 1

func _on_body_exited(body: Node2D) -> void:
	if "_ladder_count" in body:
		body._ladder_count = max(0, body._ladder_count - 1)
