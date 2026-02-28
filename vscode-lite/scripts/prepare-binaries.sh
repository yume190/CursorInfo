#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SPM_DIR="$(cd "$ROOT_DIR/../SPM" && pwd)"
BIN_DIR="$ROOT_DIR/src-tauri/bin"

mkdir -p "$BIN_DIR"

echo "[prepare-binaries] Building SPM release binaries..."
cd "$SPM_DIR"
swift build -c release --product cursor-info --product demangle

RELEASE_DIR="$SPM_DIR/.build/arm64-apple-macosx/release"
cp "$RELEASE_DIR/cursor-info" "$BIN_DIR/cursor-info"
cp "$RELEASE_DIR/demangle" "$BIN_DIR/demangle"
chmod +x "$BIN_DIR/cursor-info" "$BIN_DIR/demangle"

echo "[prepare-binaries] Copied binaries to $BIN_DIR"
