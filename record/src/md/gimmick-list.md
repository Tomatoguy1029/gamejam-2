# 既存ギミック一覧

| シーン | スクリプト | 役割 |
|---|---|---|
| `PressurePlate.tscn` | `PressurePlate.gd` | 踏んでいる間 ON になるトリガー |
| `Door.tscn` | `Door.gd` | activate で開く / deactivate で閉まる壁 |
| `Lamp.tscn` | `Lamp.gd` | activate で点灯 / deactivate で消灯する表示 |
| `Goal.tscn` | — | クリア判定エリア |
| `Platform.tscn` | `Platform.gd` | activate で出現 / deactivate で消える足場 |
| `Ladder.tscn` | `Ladder.gd` | エリア内で W / S を押すと昇降できる梯子（重力を無視する。重ねて配置可） |
| `Tutorial.tscn` | `Tutorial.gd` | プレイヤーが触れると吹き出しを出し、操作説明を追加する看板 |
| `Pulley.tscn` | `Pulley.gd` | 2 つのカゴが逆方向に動く滑車。乗っている人数が多いほうが下がる |
