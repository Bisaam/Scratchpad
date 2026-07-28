#!/bin/bash
# Builds the Scratchpad executable via SwiftPM and assembles it into a real,
# ad-hoc-signed Scratchpad.app bundle. This exists because Xcode is not
# installed on the build machine (only the Command Line Tools), so there is
# no xcodebuild/.xcodeproj in this repository yet -- see JOURNAL.md.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${1:-debug}"

APP_NAME="Scratchpad"
APP_BUNDLE="$ROOT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Building ($CONFIGURATION)"
swift build --package-path "$ROOT_DIR" -c "$CONFIGURATION"

BIN_PATH="$ROOT_DIR/.build/$CONFIGURATION/$APP_NAME"
if [ ! -f "$BIN_PATH" ]; then
    echo "error: built executable not found at $BIN_PATH" >&2
    exit 1
fi

echo "==> Assembling $APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
cp "$ROOT_DIR/Sources/Scratchpad/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# SwiftPM compiles `resources:` (e.g. PencilCursor.png) into a
# "<Package>_<Target>.bundle" folder next to the built executable, rather
# than into the executable itself. `Bundle.module`'s generated lookup checks
# `Bundle.main.resourceURL` among other candidates, which for a real .app is
# Contents/Resources -- so copying the whole bundle folder there is enough
# for Bundle.module to find it at runtime, same as it would find it in Xcode.
for resourceBundle in "$ROOT_DIR/.build/$CONFIGURATION"/*.bundle; do
    [ -d "$resourceBundle" ] && cp -R "$resourceBundle" "$RESOURCES_DIR/"
done

ICON_SOURCE="$ROOT_DIR/drawing-icon.png"
if [ -f "$ICON_SOURCE" ]; then
    echo "==> Generating AppIcon.icns from drawing-icon.png"
    ICONSET_DIR="$ROOT_DIR/.build/AppIcon.iconset"
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"

    for size in 16 32 128 256 512; do
        double=$((size * 2))
        sips -z "$size" "$size" "$ICON_SOURCE" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
        sips -z "$double" "$double" "$ICON_SOURCE" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
    done

    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
    rm -rf "$ICONSET_DIR"
else
    echo "warning: $ICON_SOURCE not found, skipping app icon" >&2
fi

echo "==> Ad-hoc code signing"
# Strip any Finder/screen-capture metadata that may have hitched a ride on a
# copied resource (codesign refuses to sign a bundle containing it).
xattr -cr "$APP_BUNDLE"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Done: $APP_BUNDLE"
