#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
DIST_DIR="$ROOT/dist"
APP_NAME="Apple RAW 9 Tester"
APP_DIR="$ROOT/.build/$APP_NAME.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
  "$ROOT/RawOptionsApp/Info.plist")
ARCHIVE_NAME="Apple-RAW-9-Tester-${VERSION}-macos-arm64.zip"
ARCHIVE_PATH="$DIST_DIR/$ARCHIVE_NAME"

rm -rf "$ROOT/.build" "$DIST_DIR"
mkdir -p "$DIST_DIR"

zsh "$ROOT/build_raw_options_app.sh" >/dev/null

codesign --verify --deep --strict --verbose=2 "$APP_DIR"
spctl --assess --type execute --verbose=2 "$APP_DIR" || true

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ARCHIVE_PATH"
shasum -a 256 "$ARCHIVE_PATH" > "$ARCHIVE_PATH.sha256"

echo "$ARCHIVE_PATH"
echo "$ARCHIVE_PATH.sha256"
