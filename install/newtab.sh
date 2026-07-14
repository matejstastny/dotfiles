#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HELIUM_WRAPPER="$DOTFILES_DIR/bin/helium"
DESKTOP_SRC="/opt/helium/helium.desktop"
DESKTOP_DST="$HOME/.local/share/applications/helium.desktop"

echo "✦ Installing new tab extension for Helium..."
mkdir -p "$(dirname "$DESKTOP_DST")"
sed "s|Exec=helium|Exec=$HELIUM_WRAPPER|g" \
	"$DESKTOP_SRC" >"$DESKTOP_DST"
echo "  installed — restart Helium to activate"
