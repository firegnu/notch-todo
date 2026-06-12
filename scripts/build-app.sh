#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/build/Notch Todo.app"
EXECUTABLE="$ROOT/.build/release/NotchTodo"
WIDGET_EXECUTABLE="$ROOT/.build/release/NotchTodoWidgetExtension"
WIDGET_APPEX="$APP/Contents/PlugIns/NotchTodoWidgetExtension.appex"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
APP_GROUP_IDENTIFIER="${APP_GROUP_IDENTIFIER:-}"
if [[ -z "$APP_GROUP_IDENTIFIER" && -n "${DEVELOPMENT_TEAM:-}" ]]; then
  APP_GROUP_IDENTIFIER="${DEVELOPMENT_TEAM}.notchtodo"
fi
APP_GROUP_IDENTIFIER="${APP_GROUP_IDENTIFIER:-group.com.firegnu.notchtodo}"

set_plist_string() {
  local plist="$1"
  local key="$2"
  local value="$3"

  if "$PLIST_BUDDY" -c "Set :$key $value" "$plist" 2>/dev/null; then
    return
  fi
  "$PLIST_BUDDY" -c "Add :$key string $value" "$plist"
}

set_app_group_entitlement() {
  local entitlements="$1"
  local group_identifier="$2"

  "$PLIST_BUDDY" -c "Delete :com.apple.security.application-groups" \
    "$entitlements" 2>/dev/null || true
  "$PLIST_BUDDY" -c "Add :com.apple.security.application-groups array" \
    "$entitlements"
  "$PLIST_BUDDY" -c "Add :com.apple.security.application-groups:0 string $group_identifier" \
    "$entitlements"
}

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

set_plist_string "$APP/Contents/Info.plist" \
  "NotchTodoAppGroupIdentifier" "$APP_GROUP_IDENTIFIER"
set_plist_string "$WIDGET_APPEX/Contents/Info.plist" \
  "NotchTodoAppGroupIdentifier" "$APP_GROUP_IDENTIFIER"

HOST_ENTITLEMENTS="$ROOT/build/NotchTodo.entitlements"
WIDGET_ENTITLEMENTS="$ROOT/build/NotchTodoWidgetExtension.entitlements"
cp "$ROOT/Resources/NotchTodo.entitlements" "$HOST_ENTITLEMENTS"
cp "$ROOT/Resources/NotchTodoWidgetExtension.entitlements" "$WIDGET_ENTITLEMENTS"
set_app_group_entitlement "$HOST_ENTITLEMENTS" "$APP_GROUP_IDENTIFIER"
set_app_group_entitlement "$WIDGET_ENTITLEMENTS" "$APP_GROUP_IDENTIFIER"

if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  printf 'Warning: using ad-hoc signing. macOS may register the widget extension, but WidgetKit may not show it in the widget gallery without a valid Apple code signing identity and Team ID based App Group.\n' >&2
else
  printf 'Signing with identity: %s\n' "$CODESIGN_IDENTITY"
fi
printf 'Using App Group: %s\n' "$APP_GROUP_IDENTIFIER"

codesign --force --options runtime \
  --entitlements "$WIDGET_ENTITLEMENTS" \
  --sign "$CODESIGN_IDENTITY" "$WIDGET_APPEX"

codesign --force --options runtime \
  --entitlements "$HOST_ENTITLEMENTS" \
  --sign "$CODESIGN_IDENTITY" "$APP"

printf 'Built %s\n' "$APP"
