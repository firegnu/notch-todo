#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILT_APP="$ROOT/build/Notch Todo.app"
INSTALLED_APP="/Applications/Notch Todo.app"

"$ROOT/scripts/build-app.sh"

pkill -f '/Notch Todo.app/Contents/MacOS/NotchTodo' 2>/dev/null || true
rm -rf "$INSTALLED_APP"
cp -R "$BUILT_APP" "$INSTALLED_APP"
open "$INSTALLED_APP"

printf 'Installed %s\n' "$INSTALLED_APP"
