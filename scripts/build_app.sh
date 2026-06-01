#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/PublicGuard.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/PublicGuard" "$MACOS_DIR/PublicGuard"
if compgen -G "$BUILD_DIR/*.bundle" > /dev/null; then
  cp -R "$BUILD_DIR"/*.bundle "$RESOURCES_DIR/"
fi
if [[ -f "$ROOT_DIR/Sources/PublicGuard/Resources/PublicGuard.icns" ]]; then
  cp "$ROOT_DIR/Sources/PublicGuard/Resources/PublicGuard.icns" "$RESOURCES_DIR/PublicGuard.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>PublicGuard</string>
  <key>CFBundleIdentifier</key>
  <string>dev.publicguard.PublicGuard</string>
  <key>CFBundleIconFile</key>
  <string>PublicGuard</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>PublicGuard</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright 2026 PublicGuard contributors</string>
  <key>NSBluetoothAlwaysUsageDescription</key>
  <string>PublicGuard uses Bluetooth locally to detect when a learned nearby device is no longer seen while the guard is armed.</string>
</dict>
</plist>
PLIST

echo "Built $APP_DIR"
echo "Run with: open \"$APP_DIR\""
