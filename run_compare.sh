#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
BUILD_DIR="$ROOT/.build"
MODULE_CACHE="$BUILD_DIR/module-cache"

mkdir -p "$BUILD_DIR" "$MODULE_CACHE"

clang \
  -fobjc-arc \
  -fblocks \
  -fmodules \
  -fmodules-cache-path="$MODULE_CACHE" \
  -framework Foundation \
  -framework CoreImage \
  -framework ImageIO \
  "$ROOT/raw_compare.m" \
  -o "$BUILD_DIR/raw_compare"

"$BUILD_DIR/raw_compare" "${1:-$ROOT/Sample raw}" "${2:-$ROOT/RAW comparison}"
