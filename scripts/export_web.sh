#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_EXECUTABLE="${GODOT_BIN:-godot}"
TEMP_EXPORT="$(mktemp -d)"
trap 'rm -rf "$TEMP_EXPORT"' EXIT

"$GODOT_EXECUTABLE" --headless --path "$PROJECT_DIR" --editor --quit
"$GODOT_EXECUTABLE" --headless --path "$PROJECT_DIR" --script res://tests/test_puzzle.gd
"$GODOT_EXECUTABLE" --headless --path "$PROJECT_DIR" --export-release Web "$TEMP_EXPORT/index.html"

for file in index.html index.js index.wasm index.pck; do
  test -s "$TEMP_EXPORT/$file"
done
mkdir -p "$PROJECT_DIR/web"
cp "$TEMP_EXPORT"/* "$PROJECT_DIR/web/"
touch "$PROJECT_DIR/web/.nojekyll"
echo "Web build ready in $PROJECT_DIR/web"
