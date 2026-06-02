#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_DIR="$ROOT_DIR/dist/artifacts"
ZIP_PATH="$ARTIFACT_DIR/PublicGuard.app.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"

cd "$ROOT_DIR"

echo "== PublicGuard release check =="
echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

echo
echo "== Swift build =="
swift build

echo
echo "== Swift test =="
swift test

echo
echo "== App bundle =="
scripts/build_app.sh
scripts/validate_app_bundle.sh

echo
echo "== Unsigned artifact dry run =="
rm -rf "$ARTIFACT_DIR"
mkdir -p "$ARTIFACT_DIR"
ditto -c -k --keepParent dist/PublicGuard.app "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"

echo "Wrote $ZIP_PATH"
echo "Wrote $CHECKSUM_PATH"

echo
echo "Release check passed."
