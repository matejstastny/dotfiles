#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/pingdotgg/t3code"
REPO_DIR="$HOME/devel/t3code"
INSTALL_DIR="$HOME/.local/share/t3code"
DESKTOP_FILE="$HOME/.local/share/applications/t3code.desktop"
ICON_BASE="$HOME/.local/share/icons/hicolor"

export PATH="$HOME/.vite-plus/bin:$PATH"

echo "✦ T3 Code build/install (fedora linux-arm64)"

echo ""
echo "✦ Checking system dependencies..."
if ! command -v magick &>/dev/null; then
    echo "  installing ImageMagick (needed to resize app icons)..."
    sudo dnf install -y ImageMagick
fi

if ! command -v vp &>/dev/null; then
    echo "  installing vite.plus (vp)..."
    curl -fsSL https://vite.plus | bash
fi

echo ""
if [ -d "$REPO_DIR/.git" ]; then
    echo "✦ Updating existing checkout at $REPO_DIR..."
    git -C "$REPO_DIR" pull --ff-only
else
    echo "✦ Cloning t3code into $REPO_DIR..."
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
fi

echo ""
echo "✦ Installing workspace dependencies..."
(cd "$REPO_DIR" && vp i)

echo ""
echo "✦ Building linux/arm64 AppImage..."
(cd "$REPO_DIR" && node scripts/build-desktop-artifact.ts --platform linux --target AppImage --arch arm64)

APPIMAGE=$(ls -t "$REPO_DIR"/release/*.AppImage | head -1)

echo ""
echo "✦ Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
tmpdir=$(mktemp -d)
(cd "$tmpdir" && "$APPIMAGE" --appimage-extract >/dev/null)
mkdir -p "$(dirname "$INSTALL_DIR")"
mv "$tmpdir/squashfs-root" "$INSTALL_DIR"
rmdir "$tmpdir"

echo ""
echo "✦ Installing icons..."
for icon in "$INSTALL_DIR"/usr/share/icons/hicolor/*/apps/t3code.png; do
    size=$(basename "$(dirname "$(dirname "$icon")")")
    mkdir -p "$ICON_BASE/$size/apps"
    cp "$icon" "$ICON_BASE/$size/apps/t3code.png"
done
command -v gtk-update-icon-cache &>/dev/null && gtk-update-icon-cache -f -t "$ICON_BASE" 2>/dev/null || true

echo ""
echo "✦ Writing launcher entry..."
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=T3 Code
Comment=Minimal web GUI for coding agents
Exec=$INSTALL_DIR/t3code --no-sandbox %U
Icon=t3code
Terminal=false
Categories=Development;
StartupWMClass=t3code
EOF

command -v update-desktop-database &>/dev/null && update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo ""
echo "✦ Done. \"T3 Code\" should now show up in your app launcher!!"
echo "  Manual launch: $INSTALL_DIR/t3code --no-sandbox"
