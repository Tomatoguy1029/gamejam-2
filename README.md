# Record

自分の過去プレイを「録画」して、その再生（ゴースト）を足場やスイッチとして使いながらゴールを目指す 2D パズルプラットフォーマー。

1 ステージは複数のループで構成される。1 ループは制限時間 30 秒。ループ終了時に、そのプレイを保存するか破棄するかを選ぶ。保存した録画は次のループ以降にゴーストとして同時再生され、プレイヤーはゴーストの頭に乗ったり、ゴーストにスイッチを踏ませたりできる。保存できる録画の本数はステージごとに決まっており（Stage 1: 3 本 / Stage 2, 3: 2 本 / Stage 4: 1 本）、それが実質的な手数制限になる。

- エンジン: Godot 4.6（Forward+）
- 言語: GDScript
- 素材: [Brackeys' Platformer Bundle](record/src/assets/brackeys_platformer_assets/)（ライセンスは同ディレクトリの `LICENSE & CREDITS.txt` を参照）

## ドキュメント

| ドキュメント | 内容 |
| ------------ | ---- |
| [要件定義](docs/requirement.md) | 何を満たすべきかの定義。コアメカニクス・ゴーストの挙動ルール・UI/演出要件、および当初設計からの差分 |
| [アーキテクチャ](docs/architecture.md) | 内部構造。マネージャ層・状態機械・録画再生のデータフロー・衝突レイヤー設計・既知の制約 |
| [詳細仕様書](docs/SPEC.md) | 画面表示・入力・物理・定数まで含む網羅的な仕様。数値の一次情報源 |
| [ギミック追加手順](record/src/md/gimmick-guide.md) / [一覧](record/src/md/gimmick-list.md) | 新しいギミックの作り方と既存ギミックの一覧 |
| [デバッグツール](docs/debug-tools.md) | 開発中に使えるデバッグ機能の一覧と使い方 |
| [テスト運用](docs/testing.md) | テストの置き場所・書き方・粒度と、今あるテストの一覧 |
| [AGENTS.md](AGENTS.md) | AI エージェント向けの作業指示（規約・不変条件・検証手順） |

## 実行方法

1. Godot 4.6 以降を用意する
2. Godot のプロジェクトマネージャで「インポート」から `record/project.godot` を選択して開く
3. エディタ右上の実行ボタン（F5）で起動する。メインシーンは [Main.tscn](record/scenes/Main.tscn)

起動するとタイトル兼ステージ選択画面が出る。初回は Stage 1 のみ選択可能で、Stage 1 をクリアすると残りのステージが解放される（解放状態はメモリ上のみで、再起動するとリセットされる）。

開発時は `./run_tests.sh` でヘッドレスのテストを実行できる。エディタのツールバーの「▶ Debug」ボタンで編集中のステージを直接起動できる（[デバッグツール](docs/debug-tools.md)）。

## 操作

| キー         | 動作                                               |
| ------------ | -------------------------------------------------- |
| A / D、← / → | 左右移動                                           |
| W / S        | はしごの上下移動                                   |
| Space        | ジャンプ。ループ開始待ち（IDLE）状態ではループ開始 |
| R            | ループを中断して終了（リトライ）                   |
| K            | 直前のループを録画として保存                       |
| L            | 直前のループを破棄                                 |

保存・破棄は画面の HUD ボタンからも行える。ループ中の残り時間と録画の残り本数は、画面上部のタイマーとバッテリー型メーターで確認できる。

## ディレクトリ構成

```
record/
├── project.godot
├── scenes/
│   ├── Main.tscn            # ルート。Manager とレベルの仲介
│   ├── actors/              # PlayerActor / GhostActor
│   ├── gimmicks/            # PressurePlate, Door, Lamp, Platform, Ladder, Goal, Tutorial
│   ├── levels/              # Level001〜004
│   ├── ui/                  # HUD, StageSelect, CameraFrame
│   └── PostProcess/         # RetryEffect
└── src/
    ├── scripts/
    │   ├── managers/        # GameManager, LoopManager, RecordingManager, WorldResetManager（Autoload）
    │   ├── game/            # Main（仲介）, Level（ステージ設定）
    │   ├── actors/          # ActorBase と Player / Ghost のサブクラス
    │   ├── data/            # InputFrame, GhostData, MovementStats, CollisionLayers
    │   ├── gimmicks/
    │   ├── ui/
    │   ├── effects/         # RetryEffect と postprocess/（Noise, Whiteout, TextShake）
    │   └── shaders/         # Noise.gdshader
    ├── data/                # MovementStats の .tres
    ├── md/                  # ギミック追加手順・一覧
    └── assets/
```

## 実装上の工夫

### 録画と再生

録画の実体はプレイヤーの座標ではなく入力そのもの。[PlayerController](record/src/scripts/actors/PlayerController.gd) が `_physics_process` ごとに [InputFrame](record/src/scripts/data/InputFrame.gd)（tick, 移動方向, ジャンプ, 上下入力）を [RecordingManager](record/src/scripts/managers/RecordingManager.gd) へ渡し、配列として蓄積する。再生側の [GhostController](record/src/scripts/actors/GhostController.gd) は自分の経過時間を持たず、`LoopManager.loop_tick` という単一のクロックでフレームを索引する。全ゴーストとプレイヤーが同じ tick を共有するため、ループを跨いでも再生タイミングがずれない。制限時間も秒ではなく `time_limit_sec * physics_ticks_per_second` で tick 化して判定している。

物理挙動は [ActorBase](record/src/scripts/actors/ActorBase.gd) が重力・ジャンプ・加減速・はしごまですべて持ち、サブクラスは `_get_input()` を上書きして入力源（キーボード / 録画データ）を差し替えるだけにした。移動パラメータも [MovementStats](record/src/scripts/data/MovementStats.gd) リソース（[player_movement.tres](record/src/data/player_movement.tres)）を両者で共有しているので、録画時と再生時で挙動がずれることが原理的に起きない。調整もエディタ上でこの 1 ファイルを触るだけで済む。

### ゴーストとの衝突

ゴーストの上に乗れる一方、ゴーストが後発のプレイヤーに押されて軌道が変わると再生が破綻する。そこで [LoopManager](record/src/scripts/managers/LoopManager.gd) がスポーン時に衝突レイヤーを動的に割り当て、「ゴースト N は World と自分より古いゴースト（0〜N-1）のみと衝突する」という一方向の関係を作っている。プレイヤー側は全ゴーストと衝突するマスクを持つ一方、ゴーストのマスクにはプレイヤーのビットが入らないため、ゴーストは後から走るプレイヤーに押されない。

足場としてのゴーストへの追従は自前で速度合成せず、`move_and_slide()` のムービングプラットフォーム機能に任せている。これにより `velocity` は常に「足場に対する相対速度」だけを表せばよく、横移動中・ジャンプ中のゴーストの上でも特別扱いが不要になる。

### 状態管理とギミックの追加

[GameManager](record/src/scripts/managers/GameManager.gd) は `MAIN_MENU / IDLE / PLAYING / PLAY_ENDED / OVER_LIMIT / CLEAR / ROOM_RETRY` の状態遷移とシグナル発火だけを担当し、ゲームロジックを持たない。HUD・演出・ゴースト管理・ギミックリセットはすべてシグナルの購読側として独立している。ワールドのリセットは Space を押してループを開始した瞬間ではなく IDLE に入った時点で走らせており、保存・破棄・削除を選んだその場で盤面が初期状態に戻る。

ギミックは共通の基底クラスやインターフェースを継承させず、メソッド名で接続している。[WorldResetManager](record/src/scripts/managers/WorldResetManager.gd) は Level 以下のノードを再帰的に走査して `reset_state()` を持つノードだけを呼び、トリガー側（PressurePlate）も `target_paths` に指定されたノードの `activate()` / `deactivate()` を `has_method()` 経由で呼ぶ。新しいギミックは決まった名前のメソッドを必要な分だけ書いて配置すれば組み込める。手順は [gimmick-guide.md](record/src/md/gimmick-guide.md)、既存ギミックの一覧は [gimmick-list.md](record/src/md/gimmick-list.md) にまとめてある。ステージ選択画面も `scenes/levels/` を実行時に走査してボタンを生成するため、`Level005.tscn` を置けばコードを変えずに増える。ステージごとの録画上限は [Level.gd](record/src/scripts/game/Level.gd) の `max_ghosts` としてインスペクタから設定する。

### 演出

保存・破棄・上限到達といった状態遷移には、それぞれ異なるポストプロセス演出（ノイズ、ホワイトアウト等）を [RetryEffect](record/src/scripts/effects/RetryEffect.gd) から再生し、何が起きたかを文字なしで区別できるようにしている。初回の保存時だけは短いノイズの代わりに軌跡の逆再生を挟み、時間を巻き戻して録画が残るというルールを一度だけ明示する。[PlayerController](record/src/scripts/actors/PlayerController.gd) が 4 物理フレームごとに座標を記録しておき、それを Tween で逆順に辿る。1 区間の時間を「総尺 / 点数」で決めているため、プレイ時間の長短にかかわらず尺は 3 秒に収まる。

チュートリアルもゲーム内で完結させている。看板 [Tutorial.gd](record/src/scripts/gimmicks/Tutorial.gd) を通過すると `tutorial_hint` シグナルが飛び、画面上部の操作説明が習得した分だけ増えていく。Stage 1 クリア後は全操作を固定表示に切り替える。
