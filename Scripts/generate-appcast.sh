#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-}"
if [ -z "$TAG" ]; then
  echo "Usage: Scripts/generate-appcast.sh <release-tag>"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DMG_PATH="$ROOT_DIR/dist/MacScreen.dmg"
APPCAST_DIR="$ROOT_DIR/dist/appcast"
ARCHIVE_NAME="MacScreen.dmg"
DOWNLOAD_URL_PREFIX="${DOWNLOAD_URL_PREFIX:-https://github.com/Nov-Two/Mac.screen/releases/download/$TAG}"
PRODUCT_LINK="${PRODUCT_LINK:-https://github.com/Nov-Two/Mac.screen}"

if [ ! -f "$DMG_PATH" ]; then
  echo "Missing $DMG_PATH. Run make package first."
  exit 1
fi

SPARKLE_BIN="$(find "$ROOT_DIR/.build/artifacts" -path '*/Sparkle/bin' -type d -print -quit 2>/dev/null)"
if [ -z "$SPARKLE_BIN" ] || [ ! -x "$SPARKLE_BIN/generate_appcast" ]; then
  echo "Sparkle tools not found. Run make build first."
  exit 1
fi

rm -rf "$APPCAST_DIR"
mkdir -p "$APPCAST_DIR"
ditto "$DMG_PATH" "$APPCAST_DIR/$ARCHIVE_NAME"

if [ -f "$ROOT_DIR/CHANGELOG.md" ]; then
  cp "$ROOT_DIR/CHANGELOG.md" "$APPCAST_DIR/MacScreen.md"
fi

if [ -n "${SPARKLE_PRIVATE_ED_KEY:-}" ]; then
  echo "$SPARKLE_PRIVATE_ED_KEY" | "$SPARKLE_BIN/generate_appcast" \
    --ed-key-file - \
    --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
    --link "$PRODUCT_LINK" \
    --maximum-deltas 0 \
    "$APPCAST_DIR"
else
  "$SPARKLE_BIN/generate_appcast" \
    --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
    --link "$PRODUCT_LINK" \
    --maximum-deltas 0 \
    "$APPCAST_DIR"
fi

echo "Generated $APPCAST_DIR/appcast.xml"
