#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$HOME/.local/share/icons/Miku-Cursor"

if [ -d "$THEME_DIR" ]; then
	echo "✦ Miku-Cursor already installed, skipping"
	exit 0
fi

echo "✦ Fetching latest Hatsune Miku cursor release..."
RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/supermariofps/hatsune-miku-windows-linux-cursors/releases/latest)
LATEST=$(echo "$RELEASE_JSON" | grep '"tag_name"' | cut -d'"' -f4)
URL=$(echo "$RELEASE_JSON" |
	grep -o '"browser_download_url": "[^"]*miku-cursor-linux\.tar\.xz"' |
	cut -d'"' -f4)

echo "✦ Downloading Miku cursors $LATEST..."
TMP=$(mktemp -d)
curl -fsSL "$URL" -o "$TMP/miku-cursor-linux.tar.xz"
tar -xJf "$TMP/miku-cursor-linux.tar.xz" -C "$TMP"

mkdir -p "$(dirname "$THEME_DIR")"
mv "$TMP/miku-cursor-linux" "$THEME_DIR"
rm -rf "$TMP"

echo ""
echo "✦ Done. Miku-Cursor $LATEST installed to $THEME_DIR"
echo "  Pick it from the cursor switcher (ALT+SHIFT+M) or: set-cursor Miku-Cursor"
