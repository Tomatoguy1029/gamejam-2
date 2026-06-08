# ギミック追加手順書

## 概要

以下の決まった名前のメソッドをスクリプトに書くだけで、システムが自動的に呼び出してくれる。

| メソッド | 呼ばれるタイミング |
|---|---|
| `reset_state()` | ループ開始・リトライ時（WorldResetManager が自動呼び出し） |
| `activate()` | PressurePlate などのトリガーに踏まれたとき |
| `deactivate()` | PressurePlate から離れたとき |

`activate()` / `deactivate()` は、**トリガーから呼ばれる側**（Door, Lamp など）が実装する。
不要なメソッドは実装しなくてよい。

---

## ステップ 1：スクリプトを作る

`res://src/scripts/gimmicks/` 以下に `.gd` ファイルを作成する。

```gdscript
## 例：踏むと光るスイッチ
extends Node2D

func activate() -> void:
    # 有効化時の処理
    pass

func deactivate() -> void:
    # 無効化時の処理
    pass

func reset_state() -> void:
    # 初期状態に戻す処理
    pass
```

---

## ステップ 2：シーンを作る

`res://scenes/gimmicks/` 以下に `.tscn` ファイルを作成する。

1. Godot エディタでシーンを新規作成
2. ルートノードに上で作ったスクリプトをアタッチ
3. 必要な子ノード（CollisionShape2D, ColorRect など）を追加
4. シーンを保存

---

## ステップ 3：レベルシーンに配置する

`res://scenes/levels/` 以下の対象レベルシーン（例：`Level002.tscn`）を開く。

1. **シーンファイルをドラッグ＆ドロップ**してレベルに追加  
   （または「インスタンスとして追加」でシーンファイルを選択）
2. 配置したいポジションに移動する

---

## ステップ 4：トリガーと接続する（必要な場合）

**PressurePlate** など、`target_paths` を持つトリガーギミックに接続する場合：

1. レベルシーン上の PressurePlate を選択
2. インスペクタの `Target Paths` に、接続先ノードのパスを追加する
   - 例：`../Door`、`../Lamp`
3. これだけで、PressurePlate を踏んだときに対象の `activate()` / `deactivate()` が呼ばれる

> `target_paths` に追加したノードは `reset_state()` も自動で呼ばれる（WorldResetManager による）。

---

## ステップ 5：動作確認

1. Godot でゲームを実行
2. プレイヤーがトリガーを踏んでギミックが動くか確認
3. ループ開始・リトライ時に `reset_state()` で初期状態に戻るか確認

---

## ファイル配置ルール

```
record/
├── scenes/gimmicks/   ← .tscn を置く
└── src/scripts/gimmicks/  ← .gd を置く
```

---

## AIへの指示

ギミックの実装完了後に必ず以下を更新すること。

- 新しいギミックを追加した場合 → `gimmick-list.md` に追記する
- 手順に変更・例外があった場合 → このファイルの該当ステップを修正する
- 新しいトリガーの仕組みを追加した場合 → 概要の表やステップ4を更新する
