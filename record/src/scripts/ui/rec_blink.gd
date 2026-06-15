## REC 表記を薄く点滅させる。CameraFrame の REC ノード（丸 Dot と文字 Label の親）に付ける。
## modulate は子へ伝播するので、これ1つで丸と文字をまとめて点滅できる。
extends Control

@export var min_alpha: float = 0.12
@export var max_alpha: float = 0.5
@export var period: float = 1.2  # 1往復にかける秒数

func _ready() -> void:
	modulate.a = min_alpha
	var tw := create_tween().set_loops()
	tw.tween_property(self, "modulate:a", max_alpha, period * 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "modulate:a", min_alpha, period * 0.5).set_trans(Tween.TRANS_SINE)
