#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
APP_DIR="$DIST_DIR/Antigravity Bridge.app"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

if [[ -z "$SIGN_IDENTITY" || -z "$NOTARY_PROFILE" ]]; then
  printf '%s\n' 'SIGN_IDENTITY and NOTARY_PROFILE are required.' >&2
  printf '%s\n' 'No signing or notarization was performed.' >&2
  exit 2
fi

VERSION="$(/usr/bin/plutil -extract CFBundleShortVersionString raw "$ROOT_DIR/packaging/Info.plist")"
SUBMISSION_ZIP="$DIST_DIR/Antigravity-Bridge-v${VERSION}-notarization.zip"
FINAL_ZIP="$DIST_DIR/Antigravity-Bridge-v${VERSION}.zip"
FINAL_DMG="$DIST_DIR/Antigravity-Bridge-v${VERSION}.dmg"
DMG_STAGING_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/antigravity-bridge-notarized-dmg.XXXXXX")"
trap '/bin/rm -rf "$DMG_STAGING_DIR"' EXIT

DIST_DIR="$DIST_DIR" "$ROOT_DIR/scripts/build.sh"
/usr/bin/codesign --force --options runtime --timestamp \
  --sign "$SIGN_IDENTITY" "$APP_DIR"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_DIR"

/bin/rm -f "$SUBMISSION_ZIP" "$FINAL_ZIP" "$FINAL_DMG" "$DIST_DIR/SHA256SUMS"
(
  cd "$DIST_DIR"
  /usr/bin/ditto -c -k --keepParent "$(basename "$APP_DIR")" "$(basename "$SUBMISSION_ZIP")"
)

/usr/bin/xcrun notarytool submit "$SUBMISSION_ZIP" \
  --keychain-profile "$NOTARY_PROFILE" --wait
/usr/bin/xcrun stapler staple "$APP_DIR"
/usr/bin/xcrun stapler validate "$APP_DIR"

/usr/bin/ditto "$APP_DIR" "$DMG_STAGING_DIR/$(basename "$APP_DIR")"
/bin/ln -s /Applications "$DMG_STAGING_DIR/Applications"
/usr/bin/hdiutil create \
  -volname "Antigravity Bridge" \
  -srcfolder "$DMG_STAGING_DIR" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$FINAL_DMG" >/dev/null
/usr/bin/xcrun notarytool submit "$FINAL_DMG" \
  --keychain-profile "$NOTARY_PROFILE" --wait
/usr/bin/xcrun stapler staple "$FINAL_DMG"
/usr/bin/xcrun stapler validate "$FINAL_DMG"

(
  cd "$DIST_DIR"
  /usr/bin/ditto -c -k --keepParent "$(basename "$APP_DIR")" "$(basename "$FINAL_ZIP")"
  /usr/bin/shasum -a 256 \
    "$(basename "$FINAL_ZIP")" \
    "$(basename "$FINAL_DMG")" > SHA256SUMS
)

/bin/rm -f "$SUBMISSION_ZIP"
printf 'Packaged notarized ZIP: %s\n' "$FINAL_ZIP"
printf 'Packaged notarized disk image: %s\n' "$FINAL_DMG"
