#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VIDEO_DIR="$ROOT_DIR/Videos"
THUMB_DIR="$ROOT_DIR/Assets/Thumbnails"
ICON_DIR="$ROOT_DIR/Assets/AppIcon"
ICON_SRC="$ICON_DIR/icon.png"
ICONSET_DIR="$ICON_DIR/MacScreenIcon.iconset"
ICON_PNG="$ICON_DIR/source-1024.png"
ICON_ICNS="$ICON_DIR/MacScreenIcon.icns"

mkdir -p "$THUMB_DIR" "$ICON_DIR"

for video in "$VIDEO_DIR"/*.mp4; do
  [[ -e "$video" ]] || continue
  name="$(basename "$video").png"
  thumb="$THUMB_DIR/$name"

  if [[ ! -f "$thumb" || "$video" -nt "$thumb" ]]; then
    tmp_dir="$(mktemp -d)"
    qlmanage -t -s 360 -o "$tmp_dir" "$video" >/dev/null 2>&1 || true
    generated="$tmp_dir/$(basename "$video").png"
    if [[ -f "$generated" ]]; then
      mv "$generated" "$thumb"
    fi
    rm -rf "$tmp_dir"
  fi
done

if [[ -f "$ICON_SRC" && ( ! -f "$ICON_ICNS" || "$ICON_SRC" -nt "$ICON_ICNS" ) ]]; then
  rm -rf "$ICONSET_DIR"
  mkdir -p "$ICONSET_DIR"

  width="$(sips -g pixelWidth "$ICON_SRC" | awk '/pixelWidth/ { print $2 }')"
  height="$(sips -g pixelHeight "$ICON_SRC" | awk '/pixelHeight/ { print $2 }')"
  side="$width"
  if (( height < width )); then
    side="$height"
  fi

  sips --cropToHeightWidth "$side" "$side" "$ICON_SRC" --out "$ICON_PNG" >/dev/null
  sips -s format png -Z 1024 "$ICON_PNG" --out "$ICON_PNG" >/dev/null

  sips -z 16 16 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

  iconutil -c icns "$ICONSET_DIR" -o "$ICON_ICNS"
fi
