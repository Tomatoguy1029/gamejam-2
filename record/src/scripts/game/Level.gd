## 各ステージのルートに付けるスクリプト。ステージ固有の設定を保持する。
class_name Level
extends Node2D

## このステージで保存できるゴーストの最大数。インスペクタでステージごとに設定する。
@export var max_ghosts: int = 3
