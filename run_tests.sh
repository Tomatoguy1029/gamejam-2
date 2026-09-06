#!/bin/sh
# ヘッドレスでテストを実行する。GODOT 環境変数で Godot の場所を上書きできる。
#   ./run_tests.sh
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
DIR="$(dirname "$0")"

# --quit-after はハング対策の保険。パースエラーでランナーが起動しないと
# quit() に到達せず永久に走り続けるため、フレーム数で強制終了させる。
OUT="$("$GODOT" --headless --path "$DIR/record" --quit-after 7200 res://tests/TestRunner.tscn 2>&1)"
CODE=$?

echo "$OUT"

if ! echo "$OUT" | grep -q "TEST SUMMARY"; then
	echo ""
	echo "ERROR: テストが最後まで実行されなかった（パースエラー等の可能性）"
	exit 1
fi
exit $CODE
