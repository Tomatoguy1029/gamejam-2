## キャラの移動パラメータ。.tres として保存し、エディタのインスペクタで調整する。
## プレイヤーとゴーストで同じリソースを共有すれば挙動が完全に一致する。
class_name MovementStats
extends Resource

@export var move_speed: float = 300.0
@export var jump_velocity: float = -700.0
@export var gravity: float = 1800.0
@export var climb_speed: float = 200.0
## 横方向の加減速（px/s^2）
@export var accel: float = 2400.0
