## 点線の角丸四角を描く Control。空き録画スロットの表示に使う。
extends Control

@export var line_color: Color = Color(1, 1, 1, 0.5)
@export var line_width: float = 4.0
@export var corner_radius: float = 16.0
@export var dash_length: float = 14.0
@export var gap_length: float = 10.0
@export var corner_segments: int = 6

func _draw() -> void:
	_draw_dashed(_rounded_rect_points())

## 角丸長方形の外周を点列で近似して返す
func _rounded_rect_points() -> PackedVector2Array:
	var w: float = size.x
	var h: float = size.y
	var r: float = minf(corner_radius, minf(w, h) * 0.5)
	var centers := [
		Vector2(w - r, r),      # 右上
		Vector2(w - r, h - r),  # 右下
		Vector2(r, h - r),      # 左下
		Vector2(r, r),          # 左上
	]
	var start_angles := [-PI * 0.5, 0.0, PI * 0.5, PI]
	var pts := PackedVector2Array()
	for ci in 4:
		var c: Vector2 = centers[ci]
		var a0: float = start_angles[ci]
		for s in corner_segments + 1:
			var a: float = a0 + (PI * 0.5) * (float(s) / float(corner_segments))
			pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts

## 閉じた点列に沿って一定間隔で線分（ダッシュ）を引く
func _draw_dashed(pts: PackedVector2Array) -> void:
	var n: int = pts.size()
	if n < 2:
		return
	var on: bool = true
	var rem: float = dash_length
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var seg: Vector2 = b - a
		var seg_len: float = seg.length()
		if seg_len <= 0.0001:
			continue
		var dir: Vector2 = seg / seg_len
		var pos: float = 0.0
		while pos < seg_len:
			var step: float = minf(rem, seg_len - pos)
			if on:
				draw_line(a + dir * pos, a + dir * (pos + step), line_color, line_width)
			pos += step
			rem -= step
			if rem <= 0.0001:
				on = not on
				rem = dash_length if on else gap_length
