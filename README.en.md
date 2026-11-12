# Countdown

English | [简体中文](README.md)

A minimal macOS desktop countdown with customizable animated themes.

## Features

- A transparent floating widget that stays on top across desktops, with adjustable size and saved position.
- Click to start, pause, or resume. Hover to reveal controls.
- Custom countdown duration, with optional remaining time and menu bar icon.
- Animations that change with progress, with optional theme completion sounds.
- Import, switch, and share themes as local ZIP files. No account or backend required.

## Download & Use

Requires **macOS 14 or later**, on Apple Silicon or Intel. [Download a release](https://github.com/yining134/Countdown/releases). Open the DMG and drag Countdown on the left to Applications on the right. Download custom skins using the ZIP links below and import them in Settings.

Current releases use ad hoc signing and are not notarized by Apple.

Click the desktop widget to start a countdown. Right-click to open Settings. In Themes, click “+” to select a ZIP or drag one onto the page. When the countdown finishes, click to reset, then click again to start.

## Custom Themes

Themes use a **PNG sprite sheet + JSON**, packaged as a ZIP file.

- [Theme creation prompt](docs/THEME_PROMPT.md): copy it to an Agent to create your own theme (prompt in Chinese).
- [Example theme](Examples/Skins/PixelSprout/PixelSprout.zip) · [Example configuration](Examples/Skins/PixelSprout/skin.json)
- [Black cat theme](Examples/Skins/BlackCat/BlackCat.zip)

## Build Locally

See [architecture and conventions](docs/ARCHITECTURE.md) and [refactoring notes](docs/REFACTOR.md) (Chinese). Run `./script/check.sh` for formatting and strict concurrency checks.

Run `./script/build_and_run.sh` to build and launch the app, or `./script/package_dmg.sh` to create a Universal Release DMG in `dist/`. Requires macOS, a Swift toolchain, and Python 3. The packaging script installs dmgbuild under `.build/` on its first run.

## Contributing

Issues, pull requests, and community themes are welcome.
