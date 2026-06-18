#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
BUILD_DIR="$ROOT/.build"
MODULE_CACHE="$BUILD_DIR/module-cache"
APP_DIR="$BUILD_DIR/Apple RAW 9 Tester.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
APP_RESOURCES_DIR="$ROOT/RawOptionsApp/Resources"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"

rm -rf "$APP_DIR"
mkdir -p "$MODULE_CACHE" "$MACOS_DIR" "$RESOURCES_DIR" "$APP_RESOURCES_DIR"

swift \
  -module-cache-path "$MODULE_CACHE" \
  "$ROOT/Tools/generate_app_icon.swift" \
  "$ROOT"

if [[ ! -f "$APP_RESOURCES_DIR/AppIcon.icns" ]]; then
  rm -rf "$ICONSET_DIR"
  mkdir -p "$ICONSET_DIR"
  sips -z 16 16 "$APP_RESOURCES_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$APP_RESOURCES_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$APP_RESOURCES_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$APP_RESOURCES_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$APP_RESOURCES_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$APP_RESOURCES_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$APP_RESOURCES_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$APP_RESOURCES_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$APP_RESOURCES_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$APP_RESOURCES_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
  if ! iconutil -c icns "$ICONSET_DIR" -o "$APP_RESOURCES_DIR/AppIcon.icns"; then
    echo "Warning: iconutil could not create AppIcon.icns; keeping AppIcon.png as a resource." >&2
  fi
fi
if [[ -f "$APP_RESOURCES_DIR/AppIcon.icns" ]]; then
  cp "$APP_RESOURCES_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

cp "$ROOT/RawOptionsApp/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$APP_RESOURCES_DIR/AppIcon.png" "$RESOURCES_DIR/AppIcon.png"

swiftc \
  -module-cache-path "$MODULE_CACHE" \
  -parse-as-library \
  -target arm64-apple-macosx27.0 \
  -framework SwiftUI \
  -framework AppKit \
  -framework CoreImage \
  -framework QuickLookThumbnailing \
  "$ROOT/RawOptionsApp/RawOptionsApp.swift" \
  -o "$MACOS_DIR/Apple RAW 9 Tester"

codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
