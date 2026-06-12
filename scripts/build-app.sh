#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/build/Notch Todo.app"
EXECUTABLE="$ROOT/.build/release/NotchTodo"
WIDGET_EXECUTABLE="$ROOT/.build/release/NotchTodoWidgetExtension"
WIDGET_APPEX="$APP/Contents/PlugIns/NotchTodoWidgetExtension.appex"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export CLANG_MODULE_CACHE_PATH="$ROOT/.build/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT/.build/swiftpm-module-cache"

cd "$ROOT"
swift build -c release --product NotchTodo
swift build -c release --product NotchTodoWidgetExtension

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mkdir -p "$WIDGET_APPEX/Contents/MacOS" "$WIDGET_APPEX/Contents/Resources"

cp "$EXECUTABLE" "$APP/Contents/MacOS/NotchTodo"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/labubu-pixel.png" "$APP/Contents/Resources/"
cp "$ROOT/Resources/labubu-pixel@2x.png" "$APP/Contents/Resources/"
cp "$ROOT/Resources/labubu-pixel@3x.png" "$APP/Contents/Resources/"
cp "$ROOT/Resources/labubu-pixel-blink.png" "$APP/Contents/Resources/"
cp "$ROOT/Resources/labubu-pixel-blink@2x.png" "$APP/Contents/Resources/"
cp "$ROOT/Resources/labubu-pixel-blink@3x.png" "$APP/Contents/Resources/"

cp "$WIDGET_EXECUTABLE" "$WIDGET_APPEX/Contents/MacOS/NotchTodoWidgetExtension"
cp "$ROOT/Resources/NotchTodoWidgetExtension-Info.plist" "$WIDGET_APPEX/Contents/Info.plist"

codesign --force --options runtime \
  --entitlements "$ROOT/Resources/NotchTodoWidgetExtension.entitlements" \
  --sign - "$WIDGET_APPEX"

codesign --force --options runtime \
  --entitlements "$ROOT/Resources/NotchTodo.entitlements" \
  --sign - "$APP"

printf 'Built %s\n' "$APP"
