#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
./script/build_and_run.sh --release-build
APP_BUNDLE="$ROOT_DIR/dist/Countdown.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
DMG="$ROOT_DIR/dist/Countdown-$VERSION-universal.dmg"
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/countdown-dmg.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
/usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
/usr/bin/lipo "$APP_BUNDLE/Contents/MacOS/Countdown" -verify_arch arm64 x86_64
/usr/bin/ditto "$APP_BUNDLE" "$STAGING/Countdown.app"
ln -s /Applications "$STAGING/Applications"
mkdir "$STAGING/Themes"
cp Examples/PixelCat/BlackCat.zip "$STAGING/Themes/BlackCat.zip"
cp Examples/StarterSkin.zip "$STAGING/Themes/PixelSprout.zip"
/usr/bin/hdiutil create -volname "Countdown $VERSION" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
/usr/bin/hdiutil verify "$DMG"
(cd "$ROOT_DIR/dist" && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
echo "$DMG"
