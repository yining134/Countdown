#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
./script/build_and_run.sh --release-build
APP_BUNDLE="$ROOT_DIR/dist/Countdown.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
DMG="$ROOT_DIR/dist/Countdown-$VERSION-universal.dmg"
/usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
/usr/bin/lipo "$APP_BUNDLE/Contents/MacOS/Countdown" -verify_arch arm64 x86_64
DMGBUILD="$ROOT_DIR/.build/dmg-tools/bin/dmgbuild"
if [ ! -x "$DMGBUILD" ]; then
  python3 -m venv "$ROOT_DIR/.build/dmg-tools"
  "$ROOT_DIR/.build/dmg-tools/bin/pip" install 'dmgbuild==1.6.7'
fi
"$DMGBUILD" -s script/packaging/dmg_settings.py -D "app=$APP_BUNDLE" -D "background=$ROOT_DIR/dist/artwork/background.png" "Countdown $VERSION" "$DMG"
/usr/bin/hdiutil verify "$DMG"
(cd "$ROOT_DIR/dist" && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
echo "$DMG"
