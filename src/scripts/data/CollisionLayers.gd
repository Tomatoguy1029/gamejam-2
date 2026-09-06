## 衝突レイヤー定数。全スクリプトからここを参照する。
class_name CollisionLayers

const WORLD   : int = 1       # bit 0
const PLAYER  : int = 1 << 1  # bit 1
const GHOST_0 : int = 1 << 2  # bit 2
const GHOST_1 : int = 1 << 3  # bit 3
const GHOST_2 : int = 1 << 4  # bit 4
const GHOST_3 : int = 1 << 5  # bit 5

const ALL_GHOSTS : int = GHOST_0 | GHOST_1 | GHOST_2 | GHOST_3
const ALL_ACTORS : int = PLAYER | ALL_GHOSTS  # = 62
