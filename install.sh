#!/usr/bin/env bash
set -euo pipefail

REPO="https://raw.githubusercontent.com/alexander-zuev/clipshot/main"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading clipshot..."
curl -fsSL "$REPO/clipshot"         -o "$TMP/clipshot"
curl -fsSL "$REPO/watcher.ps1"     -o "$TMP/watcher.ps1"
curl -fsSL "$REPO/clipshot.service" -o "$TMP/clipshot.service"
chmod +x "$TMP/clipshot"

"$TMP/clipshot" install
