#!/usr/bin/env bash
set -euo pipefail

XCODE_VERSION="16.4"
INSTALL_DIR="$HOME/Applications"
CACHE_XIP="$HOME/Library/Application Support/com.robotsandpencils.xcodes/Xcode-16.4.0+16F6.xip"

mkdir -p "$INSTALL_DIR"

# 如果上次下载被 Apple 403 拦截，xcodes 可能会留下一个很小的错误响应文件。
if [[ -f "$CACHE_XIP" ]]; then
  size="$(stat -f%z "$CACHE_XIP")"
  if [[ "$size" -lt 1000000000 ]]; then
    rm -f "$CACHE_XIP"
  fi
fi

xcodes install "$XCODE_VERSION" \
  --directory "$INSTALL_DIR" \
  --no-superuser \
  --select \
  --no-aria2

echo "Xcode $XCODE_VERSION installed under $INSTALL_DIR"
