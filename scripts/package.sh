#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
PLIST_VERSION="$(/usr/bin/plutil -extract CFBundleShortVersionString raw "$ROOT_DIR/packaging/Info.plist")"
REQUESTED_VERSION="${1:-$PLIST_VERSION}"
VERSION="${REQUESTED_VERSION#v}"

if [[ "$VERSION" != "$PLIST_VERSION" ]]; then
  printf 'Version mismatch: tag/request=%s, Info.plist=%s\n' "$VERSION" "$PLIST_VERSION" >&2
  exit 1
fi

ZIP_NAME="Antigravity-Bridge-v${VERSION}-unsigned.zip"
DMG_NAME="Antigravity-Bridge-v${VERSION}-unsigned.dmg"
APP_NAME="Antigravity Bridge.app"
DMG_VOLUME_NAME="Antigravity Bridge"
DMG_STAGING_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/antigravity-bridge-dmg.XXXXXX")"
trap '/bin/rm -rf "$DMG_STAGING_DIR"' EXIT

DIST_DIR="$DIST_DIR" "$ROOT_DIR/scripts/build.sh"
/bin/rm -f "$DIST_DIR/$ZIP_NAME" "$DIST_DIR/$DMG_NAME" "$DIST_DIR/SHA256SUMS"

/usr/bin/ditto "$DIST_DIR/$APP_NAME" "$DMG_STAGING_DIR/$APP_NAME"
/bin/ln -s /Applications "$DMG_STAGING_DIR/Applications"
/usr/bin/hdiutil create \
  -volname "$DMG_VOLUME_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$DIST_DIR/$DMG_NAME" >/dev/null
/usr/bin/hdiutil verify "$DIST_DIR/$DMG_NAME" >/dev/null

(
  cd "$DIST_DIR"
  COPYFILE_DISABLE=1 /usr/bin/zip -qry -X "$ZIP_NAME" "$APP_NAME" \
    -x '*.DS_Store' '*/.DS_Store' '._*' '*/._*' '__MACOSX/*'
  /usr/bin/shasum -a 256 "$ZIP_NAME" "$DMG_NAME" > SHA256SUMS
)

printf 'Packaged unnotarized ZIP: %s\n' "$DIST_DIR/$ZIP_NAME"
printf 'Packaged unnotarized disk image: %s\n' "$DIST_DIR/$DMG_NAME"
printf 'Checksum file: %s\n' "$DIST_DIR/SHA256SUMS"
