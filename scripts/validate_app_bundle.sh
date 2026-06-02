#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${1:-$ROOT_DIR/dist/PublicGuard.app}"
CONTENTS_DIR="$APP_DIR/Contents"
INFO_PLIST="$CONTENTS_DIR/Info.plist"
EXECUTABLE="$CONTENTS_DIR/MacOS/PublicGuard"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
BUNDLE_DIR="$RESOURCES_DIR/PublicGuard_PublicGuard.bundle"

fail() {
  echo "error: $*" >&2
  exit 1
}

expect_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

expect_executable() {
  [[ -x "$1" ]] || fail "missing executable: $1"
}

expect_plist_value() {
  local key="$1"
  local expected="$2"
  local actual

  actual="$(/usr/libexec/PlistBuddy -c "Print :$key" "$INFO_PLIST" 2>/dev/null)" ||
    fail "missing Info.plist key: $key"

  [[ "$actual" == "$expected" ]] ||
    fail "Info.plist $key expected '$expected' but found '$actual'"
}

[[ -d "$APP_DIR" ]] || fail "missing app bundle: $APP_DIR"
expect_file "$INFO_PLIST"
plutil -lint "$INFO_PLIST" >/dev/null

expect_executable "$EXECUTABLE"
expect_file "$RESOURCES_DIR/PublicGuard.icns"
expect_file "$BUNDLE_DIR/AppleAlarm.mp3"
expect_file "$BUNDLE_DIR/BeaconPulse.wav"
expect_file "$BUNDLE_DIR/HighAlert.wav"

expect_plist_value "CFBundleExecutable" "PublicGuard"
expect_plist_value "CFBundleIdentifier" "dev.publicguard.PublicGuard"
expect_plist_value "CFBundleIconFile" "PublicGuard"
expect_plist_value "CFBundleShortVersionString" "0.1.0"
expect_plist_value "CFBundleVersion" "1"
expect_plist_value "LSMinimumSystemVersion" "14.0"
expect_plist_value "NSBluetoothAlwaysUsageDescription" "PublicGuard uses Bluetooth locally to detect when a learned nearby device is no longer seen while the guard is armed."

echo "Validated $APP_DIR"
