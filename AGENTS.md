# AGENTS.md

このリポジトリで作業する AI エージェント向けの指示書。人間の開発者が読んでも構わない。

---

## 1. このプロジェクトは何か

**Record** — 自分の過去プレイを「録画」し、その再生（ゴースト）を足場やスイッチとして使ってゴールを目指す 2D パズルプラットフォーマー。Godot 4.6 / GDScript。ゲームジャム作品。

Godot プロジェクトの実体は **`record/`** 以下。リポジトリルートには README とドキュメントだけがある。

---

## 2. 最初に読むもの

| ドキュメント | 内容 | 読むべきとき |
|---|---|---|
| [README.md](README.md) | 概要・実行方法・操作・実装の工夫 | 常に |
| [docs/requirement.md](docs/requirement.md) | 要件定義。何を満たすべきか。当初設計からの差分表つき | 仕様を変える・機能を足すとき |
| [docs/architecture.md](docs/architecture.md) | 内部構造。マネージャ層・状態機械・録画再生・衝突レイヤー | コードを触る前に必ず |
| [docs/SPEC.md](docs/SPEC.md) | 画面・数値まで含む網羅的な詳細仕様 | 具体的な挙動や定数を確認したいとき |
| [record/src/md/gimmick-guide.md](record/src/md/gimmick-guide.md) | ギミック追加の手順書 | ギミックを追加するとき |
| [record/src/md/gimmick-list.md](record/src/md/gimmick-list.md) | 既存ギミック一覧 | 同上 |
| [docs/testing.md](docs/testing.md) | テストの置き場所・書き方・粒度・一覧 | テストを書く・回すとき |
| [docs/debug-tools.md](docs/debug-tools.md) | デバッグツールの一覧と使い方 | デバッグ機能を使う・作るとき |

**コードを書き始める前に `docs/architecture.md` の「設計方針」と「既知の制約」に目を通すこと。** この設計は決定論的な録画再生を成立させるために意図的な制約を置いており、それを知らずに書き換えると再生が壊れる。

---

## 3. リポジトリ地図

```
.
├── README.md
├── AGENTS.md                      # このファイル
├── docs/                          # requirement.md / architecture.md / SPEC.md
└── record/                        # ← Godot プロジェクトルート
    ├── project.godot              # Autoload 登録・入力マップ・表示設定
    ├── scenes/                    # .tscn（Main / actors / gimmicks / levels / ui / PostProcess）
    └── src/
        ├── scripts/               # .gd（managers / game / actors / data / gimmicks / ui / effects / shaders）
        ├── data/                  # player_movement.tres
        ├── md/                    # ギミック関連ドキュメント
        └── assets/                # Brackeys' Platformer Bundle ほか
```

**配置規約**：スクリプトは `src/scripts/<領域>/`、シーンは `scenes/<領域>/`。対になるように名前を揃える（`PressurePlate.gd` ↔ `PressurePlate.tscn`）。

---

## 4. 実行と検証

Godot 4.6 が必要（動作確認は 4.6.3 stable）。macOS では `/Applications/Godot.app/Contents/MacOS/Godot`。

```bash
# テストを実行する（record/tests/ の test_*.gd を一括実行。失敗があれば exit 1）
./run_tests.sh

# スクリプト・シーンが壊れていないかの確認（画面を開かずに読み込んで終了）
/Applications/Godot.app/Contents/MacOS/Godot --headless --path record --quit

# 実際にプレイして確認（エディタを開く）
/Applications/Godot.app/Contents/MacOS/Godot --path record --editor
```

- **テストの運用は [docs/testing.md](docs/testing.md) にまとめてある。** 置き場所・書き方・粒度の方針・今あるテストの一覧はそちらを見ること。
- テストで確認できるのはロジックまで。**見た目・操作感の確認はプレイが必要**。
- ヘッドレス実行では `uid://cmovestats0001` に関する警告が 2 件出るが、**これは既知で無害**（テキストパスで解決される）。新しいエラーや警告が増えていないかで判断すること。
- ゲームロジックの検証はプレイが必要。エージェントがプレイできない場合は、**何を人間に確認してほしいかを明示して報告する**（例：「Stage 3 で 2 本目のゴーストがスイッチを踏み続けるか」）。
- `record/.godot/` は生成物。コミットしない（`.gitignore` 済み）。

---

## 5. 絶対に壊してはいけない不変条件

以下は録画再生の根幹。変更する場合は必ず理由を明示し、影響範囲を報告すること。

1. **ゴーストに独自の時計を持たせない。** 全アクターは `LoopManager.loop_tick` という単一クロックを索引する。ゴーストごとに経過時間を持たせるとループを跨いで再生がずれる。
2. **座標を記録しない。** 記録するのは `InputFrame`（入力）だけ。座標を記録するとワールドの状態が変わったときにゴーストが破綻する。
3. **物理コードを分岐させない。** プレイヤーとゴーストは `ActorBase._apply_physics()` を共有し、サブクラスは `_get_input()` だけを上書きする。「ゴーストのときだけ〜」という分岐を物理に入れない。
4. **移動パラメータを二重管理しない。** `player_movement.tres`（`MovementStats`）を両アクターが共有する。片方だけ数値を直書きしない。
5. **衝突の一方向性を崩さない。** ゴースト N は World と Ghost_0〜N-1 とだけ衝突する。ゴーストのマスクにプレイヤーのビットを入れると、ゴーストが押されて軌道が変わる。
6. **`GameManager` にゲームロジックを入れない。** 状態遷移とシグナル発火だけを持たせ、処理は購読側に置く。
7. **ワールドのリセットは IDLE 進入時に走らせる。** ループ開始（Space）時に移すと、保存・破棄を選んだ後に盤面が戻らず違和感が出る。
8. **ギミックに基底クラスやインターフェースを継承させない。** `reset_state()` / `activate()` / `deactivate()` というメソッド名の規約だけで繋ぐ。
9. **時間は秒ではなく tick で判定する。** 制限時間の判定は `loop_tick >= max_tick`。

---

## 6. コーディング規約

- **GDScript**。C# は使わない（`project.godot` に `[dotnet]` セクションが残っているが未使用）。
- **インデントはタブ**（Godot 標準）。
- **型注釈を書く**：`func foo(bar: int) -> void:`、`var x: float = 0.0`。推論が明らかな場合は `:=` を使ってよい。
- **コメントは日本語**。ファイル冒頭とクラス・重要メソッドには `##` のドキュメントコメントを置く。既存ファイルの密度と語り口に合わせる。
- **「なぜ」を書く**。既存コードは「何をしているか」より「なぜその実装なのか」（例：ムービングプラットフォーム機能に委ねる理由、IDLE でリセットする理由）を残している。これを踏襲する。
- **`@export` を活用する**。調整したい値はインスペクタから触れるようにし、マジックナンバーをスクリプトに埋めない。
- **セクション区切り**は既存の `# ── 見出し ────` 形式に揃える。
- ノード参照は `@onready var _foo: Type = $Path`。プライベートなメンバは `_` 始まり。

---

## 7. よくある作業のレシピ

### ギミックを追加する
[record/src/md/gimmick-guide.md](record/src/md/gimmick-guide.md) の手順に従う。要点は「`src/scripts/gimmicks/` に `.gd`、`scenes/gimmicks/` に `.tscn`、必要なメソッド（`reset_state` / `activate` / `deactivate`）だけ実装してレベルに配置」。
**完了後に [gimmick-list.md](record/src/md/gimmick-list.md) へ追記すること。**

### ステージを追加する
`scenes/levels/Level005.tscn` を作り、ルートに `Level.gd` をアタッチ、`SpawnPoint`（`Marker2D`）と `Goal` を置き、インスペクタで `max_ghosts` を設定する。**コード変更は不要**（`StageSelect` がディレクトリを走査して自動でボタンを出す）。

### キャラクターの移動感を調整する
`record/src/data/player_movement.tres` をエディタで編集する。プレイヤーとゴーストの両方に同時に反映される。スクリプトの既定値は触らない。

### 演出を追加・差し替える
`PostProcess` を継承したノードを作って `play()` を実装し、`RetryEffect.tscn` に子として追加、ルートの `@export`（`on_save` / `on_discard` / `on_over_limit` / `on_rewind`）にノードパスを繋ぐ。新しい契機が必要なら `GameManager` にシグナルを足し、`RetryEffect._ready()` で購読する。

### ステージごとの録画上限を変える
ステージルートの `max_ghosts` をインスペクタで変更する（現状 Stage 1: 3 / Stage 2: 2 / Stage 3: 2 / Stage 4: 1）。

### テストを追加する
`record/tests/test_<対象>.gd` を作り、`Node` を継承して `func run_tests(t) -> void:` を実装し、**末尾で必ず `t.done()`** を呼ぶ。書き方の雛形・粒度の判断・Autoload の後始末は [docs/testing.md](docs/testing.md) を参照。

### デバッグツールを追加する
すべて `OS.has_feature("editor")` でガードし、製品ビルドに出ないようにする。既存クラスにデバッグ用のメソッドやフラグを生やさず、既存の公開 API とシグナルだけで実現する。
ショートカットが要るなら `DebugMenu.gd` に `@export var <名前>_shortcut: Shortcut` を足し、`_build_shortcuts()` に `_bind()` を1行足す（`project.godot` の入力マップは使わない）。
**完了後に [docs/debug-tools.md](docs/debug-tools.md) へ使い方（起動方法・できること・注意点）を追記すること。**

---

## 8. ドキュメントの更新義務

コードを変えたら、対応するドキュメントも同じ変更で更新すること。

| 変更した内容 | 更新するドキュメント |
|---|---|
| ギミックを追加・変更した | `record/src/md/gimmick-list.md`（手順が変わったなら `gimmick-guide.md` も） |
| デバッグツールを追加・変更した | `docs/debug-tools.md`（使い方を短く追記する） |
| テストを追加・削除した | `docs/testing.md` の「今あるテスト」一覧を更新する |
| 仕様・ルールを変えた | `docs/requirement.md`、`docs/SPEC.md` |
| 構造・責務・データフローを変えた | `docs/architecture.md` |
| 操作・実行方法・ディレクトリを変えた | `README.md` |
| 定数・数値（制限時間、移動パラメータ、色など）を変えた | `docs/SPEC.md`（数値の一次情報源） |

ドキュメント内の数値や挙動の記述は、**推測ではなく実装を読んで書く**こと。古い記述を見つけたら黙って残さず、実装に合わせて直すか、実装と食い違っている旨を報告する。

---

## 9. Git

- ブランチ名は `feature/<担当者>/<内容>`（例：`feature/wakida/playback`）。
- **コミットメッセージは日本語の短い名詞句・体言止め**（例：「バッテリーの上に録画回数の表記を追加」「ステージごとのゴースト数を設定」）。既存の履歴に合わせる。
- コミット・プッシュはユーザーに指示されたときだけ行う。
- `main` へ直接コミットしない。
- `record/.godot/`、`.DS_Store` はコミットしない。
- **仕様書・設計メモなどの作業用ドキュメントは `docs/wip/` に置く。**このディレクトリは `.gitignore` 済みで、コミットしない。リポジトリに残すのは確定した内容だけにする。

---

## 10. 作業時の心得

- **実装を一次情報源として扱う。** README やドキュメントに古い記述が残っていることがある（過去に C#・掴み投げ・敵といった当初案が書かれていた）。食い違ったら実装が正しい。
- **スコープを勝手に広げない。** 未実装の当初案（掴み・投げ、敵、軌跡プレビュー）は意図的に見送られている。依頼されていないのに実装しない。
- **決定論に関わる変更は影響を明示する。** 物理・クロック・衝突レイヤーに触れたら、既存ステージの解法が壊れていないかの確認を求める。
- ゲームジャム作品として、**セーブ機能・音・キャラクターアートは意図的にスコープ外**。これらを「不足」として勝手に補わない。
