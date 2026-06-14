extends Control
# CameraFrame(Control, アンカー=Full Rect)に付ける。
# 角の括弧と中央の十字を _draw() で描く静的な装飾。

@export var line_color: Color = Color.WHITE
@export var line_width: float = 4.0
@export var corner_length: float = 60.0   # 角の括弧の長さ（縦横）
@export var margin: float = 28.0          # 画面端からの内側余白
@export var crosshair_size: float = 18.0  # 中央十字の半径（中心から端まで）

func _ready() -> void:
	resized.connect(queue_redraw)   # 画面サイズが変わったら描き直す

func _draw() -> void:
	_draw_corners()
	_draw_crosshair()

func _draw_corners() -> void:
	var w := size.x
	var h := size.y
	var m := margin
	var l := corner_length
	# 各角を「横線＋縦線」のL字で描く
	# 左上
	draw_line(Vector2(m, m),         Vector2(m + l, m),     line_color, line_width)
	draw_line(Vector2(m, m),         Vector2(m, m + l),     line_color, line_width)
	# 右上
	draw_line(Vector2(w - m, m),     Vector2(w - m - l, m), line_color, line_width)
	draw_line(Vector2(w - m, m),     Vector2(w - m, m + l), line_color, line_width)
	# 左下
	draw_line(Vector2(m, h - m),     Vector2(m + l, h - m), line_color, line_width)
	draw_line(Vector2(m, h - m),     Vector2(m, h - m - l), line_color, line_width)
	# 右下
	draw_line(Vector2(w - m, h - m), Vector2(w - m - l, h - m), line_color, line_width)
	draw_line(Vector2(w - m, h - m), Vector2(w - m, h - m - l), line_color, line_width)

func _draw_crosshair() -> void:
	var c := size * 0.5          # 画面中央　
	var s := crosshair_size
	draw_line(c - Vector2(s, 0), c + Vector2(s, 0), line_color, line_width)
	draw_line(c - Vector2(0, s), c + Vector2(0, s), line_color, line_width)
