## 録画可能回数（= max_ghosts - ghost_count）をバッテリー風に表示
extends Control

@export var color_full: Color = Color(0.55, 0.85, 0.2)   # 黄緑
@export var color_mid: Color = Color(0.95, 0.8, 0.1)      # 黄
@export var color_low: Color = Color(0.9, 0.2, 0.15)      # 赤
@export var outline_color: Color = Color.WHITE
@export var outline_width: float = 4.0
@export var seg_skew_ratio: float = 0.45   # セグメントの傾き（高さに対する比）
@export var seg_gap: float = 6.0           # セグメント間の隙間

## メーターに重ねて残り回数を表示するラベル（任意）
@onready var _count_label: Label = $Count

func _ready() -> void:
	GameManager.ghost_saved.connect(queue_redraw)
	GameManager.ghost_discarded.connect(queue_redraw)
	GameManager.over_limit.connect(queue_redraw)
	GameManager.state_changed.connect(func(_s: int) -> void: queue_redraw())

func _draw() -> void:
	var maxn: int = maxi(1, LoopManager.max_ghosts)
	var remaining: int = clampi(LoopManager.max_ghosts - LoopManager.ghost_count, 0, maxn)

	# メーターに重ねて残り回数を表示（0 のときは数字を出さない）
	if _count_label != null:
		_count_label.text = str(remaining) if remaining > 0 else ""

	# 残量ゼロは赤枠＋斜線（バッテリー無効アイコン）、それ以外は白枠
	var empty: bool = remaining <= 0
	var frame_col: Color = color_low if empty else outline_color

	# 本体（枠）と右の端子
	var nub_w: float = size.x * 0.06
	var body := Rect2(Vector2.ZERO, Vector2(size.x - nub_w, size.y))
	draw_rect(body, frame_col, false, outline_width)
	var nub_h: float = size.y * 0.4
	draw_rect(Rect2(body.end.x, (size.y - nub_h) * 0.5, nub_w, nub_h), frame_col, true)

	if empty:
		draw_line(Vector2(body.position.x, body.end.y), Vector2(body.end.x, body.position.y), frame_col, outline_width)
		return

	# 内側のセグメント領域
	var pad: float = outline_width + 6.0
	var inner := Rect2(body.position + Vector2(pad, pad), body.size - Vector2(pad * 2.0, pad * 2.0))
	var col := _level_color(remaining, maxn)
	var skew: float = inner.size.y * seg_skew_ratio
	var slot_w: float = (inner.size.x - skew - seg_gap * float(maxn - 1)) / float(maxn)
	var yt: float = inner.position.y
	var yb: float = inner.end.y
	for i in remaining:
		var x0: float = inner.position.x + float(i) * (slot_w + seg_gap)
		var pts := PackedVector2Array([
			Vector2(x0 + skew, yt),
			Vector2(x0 + skew + slot_w, yt),
			Vector2(x0 + slot_w, yb),
			Vector2(x0, yb),
		])
		draw_colored_polygon(pts, col)

func _level_color(remaining: int, maxn: int) -> Color:
	if remaining >= maxn:
		return color_full
	elif remaining <= 1:
		return color_low
	return color_mid
