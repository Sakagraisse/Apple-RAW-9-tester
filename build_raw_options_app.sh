#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
BUILD_DIR="$ROOT/.build"
MODULE_CACHE="$BUILD_DIR/module-cache"
APP_DIR="$BUILD_DIR/RAW Options.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

mkdir -p "$MODULE_CACHE" "$MACOS_DIR"
cp "$ROOT/RawOptionsApp/Info.plist" "$CONTENTS_DIR/Info.plist"

swiftc \
  -module-cache-path "$MODULE_CACHE" \
  -parse-as-library \
  -target arm64-apple-macosx27.0 \
  -framework SwiftUI \
  -framework AppKit \
  -framework CoreImage \
  "$ROOT/RawOptionsApp/RawOptionsApp.swift" \
  -o "$MACOS_DIR/RAW Options"

echo "$APP_DIR"
