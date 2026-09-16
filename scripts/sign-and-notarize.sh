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

DIST_DIR="$DIST_DIR" "$ROOT_DIR/scripts/build.sh"
/usr/bin/codesign --force --options runtime --timestamp \
  --sign "$SIGN_IDENTITY" "$APP_DIR"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_DIR"

/bin/rm -f "$SUBMISSION_ZIP" "$FINAL_ZIP" "$DIST_DIR/SHA256SUMS"
(
  cd "$DIST_DIR"
  /usr/bin/ditto -c -k --keepParent "$(basename "$APP_DIR")" "$(basename "$SUBMISSION_ZIP")"
)

/usr/bin/xcrun notarytool submit "$SUBMISSION_ZIP" \
  --keychain-profile "$NOTARY_PROFILE" --wait
/usr/bin/xcrun stapler staple "$APP_DIR"
/usr/bin/xcrun stapler validate "$APP_DIR"

(
  cd "$DIST_DIR"
  /usr/bin/ditto -c -k --keepParent "$(basename "$APP_DIR")" "$(basename "$FINAL_ZIP")"
  /usr/bin/shasum -a 256 "$(basename "$FINAL_ZIP")" > SHA256SUMS
)

/bin/rm -f "$SUBMISSION_ZIP"
printf 'Packaged notarized release: %s\n' "$FINAL_ZIP"
