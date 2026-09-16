#!/bin/bash

# The launcher is sourced in library mode below. ShellCheck cannot infer that
# the guard returns instead of exiting, or that stub functions are called by
# functions loaded from the sourced file.
# shellcheck disable=SC2317,SC2329

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/antigravity-bridge-tests.XXXXXX")"
trap '/bin/rm -rf "$TEST_TMP"' EXIT

assert_equal() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  if [[ "$expected" != "$actual" ]]; then
    printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_file_equal() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  if ! /usr/bin/cmp -s "$expected" "$actual"; then
    printf 'FAIL: %s\n' "$message" >&2
    exit 1
  fi
}

/bin/bash -n "$ROOT_DIR/src/antigravity-bridge"
/usr/bin/plutil -lint "$ROOT_DIR/packaging/Info.plist" >/dev/null

export ANTIGRAVITY_PROXY_LIBRARY_ONLY=1
export ANTIGRAVITY_BRIDGE_CONFIG_DIR="$TEST_TMP/config"
# shellcheck disable=SC1091
source "$ROOT_DIR/src/antigravity-bridge"
unset ANTIGRAVITY_PROXY_LIBRARY_ONLY

for port in 1 80 65535; do
  is_valid_port "$port" || { printf 'FAIL: valid port rejected: %s\n' "$port" >&2; exit 1; }
done
for port in 0 65536 abc ''; do
  if is_valid_port "$port"; then
    printf 'FAIL: invalid port accepted: %s\n' "$port" >&2
    exit 1
  fi
done

assert_equal 160 "$(score_candidate 'macOS 系统代理' http 127.0.0.1 1)" 'system HTTP score'
assert_equal 25 "$(score_candidate Surge socks5 localhost 0)" 'Surge SOCKS score'

add_candidate() {
  printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"
}

clash_result="$(parse_clash_config Fixture "$ROOT_DIR/tests/fixtures/clash-config.yaml")"
assert_equal $'Fixture|http|127.0.0.1|17890\nFixture|http|127.0.0.1|17891\nFixture|socks5|127.0.0.1|17892' \
  "$clash_result" 'Clash fixture parsing'

surge_result="$(parse_surge_profile "$ROOT_DIR/tests/fixtures/surge-profile.conf")"
assert_equal $'Surge|http|127.0.0.1|16152\nSurge|socks5|0.0.0.0|16153' \
  "$surge_result" 'Surge fixture parsing'

build_proxy_urls http 127.0.0.1 7890
assert_equal 'http://127.0.0.1:7890' "$ENV_PROXY_URL" 'HTTP environment proxy URL'
assert_equal 'http://127.0.0.1:7890' "$CHROMIUM_PROXY_URL" 'HTTP Chromium proxy URL'
build_proxy_urls socks5 localhost 7891
assert_equal 'socks5h://localhost:7891' "$ENV_PROXY_URL" 'SOCKS environment proxy URL'
assert_equal 'socks5://localhost:7891' "$CHROMIUM_PROXY_URL" 'SOCKS Chromium proxy URL'

FAKE_APP="$TEST_TMP/Antigravity IDE.app"
/bin/mkdir -p "$FAKE_APP/Contents"
/usr/bin/plutil -create xml1 "$FAKE_APP/Contents/Info.plist"
/usr/bin/plutil -insert CFBundleIdentifier -string com.google.antigravity-ide \
  "$FAKE_APP/Contents/Info.plist"

SELECTED_TYPE=http
SELECTED_HOST=127.0.0.1
SELECTED_PORT=7890
SELECTED_SOURCE=Test
ANTIGRAVITY_PATH="$FAKE_APP"
save_config
assert_equal 600 "$(/usr/bin/stat -f '%Lp' "$CONFIG_FILE")" 'config file permissions'

SELECTED_TYPE=''
SELECTED_HOST=''
SELECTED_PORT=''
SELECTED_SOURCE=''
ANTIGRAVITY_PATH=''
proxy_is_usable() { return 0; }
load_saved_config
assert_equal http "$SELECTED_TYPE" 'saved proxy type'
assert_equal 127.0.0.1 "$SELECTED_HOST" 'saved proxy host'
assert_equal 7890 "$SELECTED_PORT" 'saved proxy port'
assert_equal Test "$SELECTED_SOURCE" 'saved proxy source'
assert_equal "$FAKE_APP" "$ANTIGRAVITY_PATH" 'saved Antigravity path'

BUILD_DIST="$TEST_TMP/build"
DIST_DIR="$BUILD_DIST" "$ROOT_DIR/scripts/build.sh" >/dev/null
APP_DIR="$BUILD_DIST/Antigravity Bridge.app"
/usr/bin/codesign --verify --deep --strict "$APP_DIR"
assert_file_equal "$ROOT_DIR/src/antigravity-bridge" \
  "$APP_DIR/Contents/MacOS/antigravity-bridge" 'bundled executable matches source'
assert_file_equal "$ROOT_DIR/packaging/Info.plist" \
  "$APP_DIR/Contents/Info.plist" 'bundled plist matches source'

PACKAGE_DIST="$TEST_TMP/package"
DIST_DIR="$PACKAGE_DIST" "$ROOT_DIR/scripts/package.sh" v2.2.0 >/dev/null
ZIP_FILE="$PACKAGE_DIST/Antigravity-Bridge-v2.2.0-unsigned.zip"
/usr/bin/unzip -t "$ZIP_FILE" >/dev/null
if /usr/bin/unzip -Z1 "$ZIP_FILE" | /usr/bin/grep -E '(^|/)(__MACOSX|\.DS_Store|\._)' >/dev/null; then
  printf 'FAIL: release ZIP contains macOS metadata\n' >&2
  exit 1
fi
(
  cd "$PACKAGE_DIST"
  /usr/bin/shasum -a 256 -c SHA256SUMS >/dev/null
)

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$ROOT_DIR/src/antigravity-bridge" "$ROOT_DIR/scripts/"*.sh "$ROOT_DIR/tests/run-tests.sh"
else
  printf 'NOTE: shellcheck is not installed; static lint was skipped.\n'
fi

printf 'All tests passed.\n'
