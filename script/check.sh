#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
xcrun swift-format lint --strict --recursive Sources Package.swift script/packaging/release_art.swift
swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
