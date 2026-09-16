#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
APP_NAME="Antigravity Bridge.app"
APP_DIR="$DIST_DIR/$APP_NAME"

/bin/rm -rf "$APP_DIR"
/bin/mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
/usr/bin/install -m 755 "$ROOT_DIR/src/antigravity-bridge" \
  "$APP_DIR/Contents/MacOS/antigravity-bridge"
/bin/cp "$ROOT_DIR/packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
/bin/cp "$ROOT_DIR/resources/AntigravityBridge.icns" \
  "$APP_DIR/Contents/Resources/AntigravityBridge.icns"

/usr/bin/plutil -lint "$APP_DIR/Contents/Info.plist" >/dev/null
/usr/bin/codesign --force --sign - "$APP_DIR"
/usr/bin/codesign --verify --deep --strict "$APP_DIR"

printf 'Built ad-hoc signed app: %s\n' "$APP_DIR"
