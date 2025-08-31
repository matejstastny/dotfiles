#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------------------------------------
# install_assets.sh — Dotfiles Assets Installer
# --------------------------------------------------------------------------------------------
# Description:
#   This script installs fonts, wallpapers, and clones the dotfiles repository.
#
# Usage:
#   install_assets.sh
#
# Notes:
#   - Ensure this script is executable: chmod +x install_assets.sh
# --------------------------------------------------------------------------------------------

log() {
    local level="$1"
    local msg="$2"
    local emoji
    case "$level" in
    info) emoji="📦" ;;
    success) emoji="✅" ;;
    warn) emoji="⚠️" ;;
    error) emoji="❌" ;;
    *) emoji="🔷" ;;
    esac
    echo -e "$emoji $msg"
}

# --------------------------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------------------------

if [ ! -d "$HOME/.dotfiles" ]; then
    git clone https://github.com/my-daarlin/dotfiles.git "$HOME/.dotfiles"
fi

# Fonts
log info "Installing fonts..."
if [ -d "$HOME/.dotfiles/assets/fonts/" ]; then
    find "$HOME/.dotfiles/assets/fonts/" \( -name "*.ttf" -o -name "*.otf" \) -print0 | while IFS= read -r -d '' font; do
        cp "$font" "$HOME/Library/Fonts/"
    done
    log success "Fonts installed."
else
    log warn "No fonts directory found."
fi

# Wallpaper
if [ -f "$HOME/.dotfiles/assets/wallpapers/mac-wallpaper.png" ]; then
    log info "Setting wallpaper..."
    if command -v wallpaper >/dev/null 2>&1; then
        wallpaper "$HOME/.dotfiles/assets/wallpapers/mac-wallpaper.png"
        log success "Wallpaper set."
    else
        # Fallback to AppleScript for macOS
        if [[ "$(uname)" == "Darwin" ]]; then
            osascript -e '
            tell application "System Events"
                set picture of every desktop to "'"$HOME/.dotfiles/assets/mac-wallpaper.png"'"
            end tell' && log success "Wallpaper set via AppleScript." || log warn "Failed to set wallpaper via AppleScript."
        else
            log warn "wallpaper-cli not installed and no macOS fallback available. Skipping setting wallpaper."
        fi
    fi
else
    log warn "Wallpaper not found."
fi

log success "Asset installation complete!"
