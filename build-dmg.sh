#!/usr/bin/env bash

set -euo pipefail

#
# build-dmg.sh
# Build "Vuender" in .app and package it into .dmg
#

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build"
APP_NAME="Vuender"
EXECUTABLE_NAME="vuender"

VERSION="0.1.0"
BUILD_NUMBER="1"

APP_VERSION_FILE="$PROJECT_ROOT/Sources/vuender/Core/AppVersion.swift"
if [[ -f "$APP_VERSION_FILE" ]]; then
  VERSION_LINE="$(grep 'static let version' "$APP_VERSION_FILE" || true)"
  BUILD_LINE="$(grep 'static let build' "$APP_VERSION_FILE" || true)"

  if [[ -n "$VERSION_LINE" ]]; then
    VERSION="$(echo "$VERSION_LINE" | sed -E 's/.*"([^"]+)".*/\1/')"
  fi

  if [[ -n "$BUILD_LINE" ]]; then
    BUILD_NUMBER="$(echo "$BUILD_LINE" | sed -E 's/.*"([^"]+)".*/\1/')"
  fi
fi

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="$PROJECT_ROOT/$DMG_NAME"

echo "==> Building release version Vuender..."
swift build -c release

EXECUTABLE_PATH="$BUILD_DIR/release/$EXECUTABLE_NAME"
if [[ ! -f "$EXECUTABLE_PATH" ]]; then
  echo "Error: not found binary file $EXECUTABLE_PATH"
  exit 1
fi

APP_BUNDLE_DIR="$BUILD_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Creating .app bundle..."
rm -rf "$APP_BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$EXECUTABLE_PATH" "$MACOS_DIR/$EXECUTABLE_NAME"
chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"

INFO_PLIST_PATH="$CONTENTS_DIR/Info.plist"

cat > "$INFO_PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>com.vuender.app</string>
  <key>CFBundleExecutable</key>
  <string>${EXECUTABLE_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>LSMinimumSystemVersion</key>
  <string>26.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

echo "==> Creating .dmg image: ${DMG_NAME}..."
rm -f "$DMG_PATH"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$APP_BUNDLE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Done: $DMG_PATH"
