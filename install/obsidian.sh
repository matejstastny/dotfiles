#!/usr/bin/env bash
set -euo pipefail

exec > >(tee -a "$HOME/out.log") 2>&1

OBSIDIAN_DIR="$HOME/.local/share/obsidian"

if [ -f "$OBSIDIAN_DIR/obsidian.AppImage" ]; then
	echo "==> Obsidian already installed, skipping"
	exit 0
fi

echo "==> Installing FUSE 2 (required by AppImages)..."
sudo dnf install -y fuse

echo "==> Fetching latest Obsidian release info..."
RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest)
LATEST=$(echo "$RELEASE_JSON" | grep '"tag_name"' | cut -d'"' -f4)
URL=$(echo "$RELEASE_JSON" |
	grep -o '"browser_download_url": "[^"]*arm64\.AppImage"' |
	cut -d'"' -f4)

echo "==> Downloading Obsidian $LATEST (arm64)..."
mkdir -p "$OBSIDIAN_DIR"
curl -fsSL "$URL" -o "$OBSIDIAN_DIR/obsidian.AppImage"
chmod +x "$OBSIDIAN_DIR/obsidian.AppImage"

echo "==> Creating desktop entry..."
mkdir -p "$HOME/.local/share/applications"
cat >"$HOME/.local/share/applications/obsidian.desktop" <<EOF
[Desktop Entry]
Name=Obsidian
Exec=$HOME/.local/share/obsidian/obsidian.AppImage --appimage-extract-and-run %u
Icon=obsidian
Type=Application
Categories=Office;
MimeType=x-scheme-handler/obsidian;
EOF
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo ""
echo "Done! Obsidian $LATEST installed."
echo "  CLI:      obsidian"
echo "  Vault:    ~/notes"
