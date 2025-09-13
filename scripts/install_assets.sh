#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/logging.sh"

# --------------------------------------------------------------------------------------------
# install_assets.sh — Dotfiles Fonts and Wallpapers Installer
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-08-19 (YYYY-MM-DD)
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------
# Description:
#   This script automates the installation of fonts and the setting of wallpapers as part of
#   the dotfiles setup
#
# Actions performed:
#   1. OS Detection & Font Directory:
#       The script determines the appropriate target font directory based on the detected OS:
#         * On macOS (Darwin), it uses "$HOME/Library/Fonts"
#         * On Linux, it uses "$HOME/.local/share/fonts"
#         * On unsupported OSes, font installation is skipped
#
#   2. Font Installation:
#       On Linux and MacOS the script finds all .ttf and .otf files and copies them into the
#       target system font directory
#
#   3. Wallpaper Setting:
#       If the wallpaper file ($WALLPAPER) exists:
#         * On macOS: Attempts to use wallpaper-cli (https://github.com/sindresorhus/wallpaper-cli)
#           if available, otherwise falls back to AppleScript via osascript.
#         * On Linux: Wallpaper setting is not implemented
#         * On other OSes: Skipped
# --------------------------------------------------------------------------------------------

if [[ "$OS_TYPE" == "Darwin" ]]; then
    TARGET_FONT_DIR="$HOME/Library/Fonts"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    TARGET_FONT_DIR="$HOME/.local/share/fonts"
else
    log warn "Unsupported OS: $OS_TYPE. Font installation skipped."
    TARGET_FONT_DIR=""
fi

# --------------------------------------------------------------------------------------------
# Fonts
# --------------------------------------------------------------------------------------------

if [[ -n "$TARGET_FONT_DIR" ]]; then
    log info "Installing fonts ..."
    log info "Font source directory: $FONT_DIR"
    log info "Target font directory: $TARGET_FONT_DIR"
    mkdir -p "$TARGET_FONT_DIR"
    if [ -d "$FONT_DIR" ]; then
        mapfile -d '' fonts < <(find "$FONT_DIR" \( -name "*.ttf" -o -name "*.otf" \) -print0)
        font_count=${#fonts[@]}
        if ((font_count > 0)); then
            log info "Found $font_count font(s) to install."
            for font in "${fonts[@]}"; do
                if cp "$font" "$TARGET_FONT_DIR/"; then
                    log success "Installed font: $(basename "$font")"
                else
                    log warn "Failed to install font: $(basename "$font")"
                fi
            done
        else
            log warn "No font files found in $FONT_DIR."
        fi
    else
        log warn "No fonts directory found at $FONT_DIR."
    fi
fi

# --------------------------------------------------------------------------------------------
# Wallpapers
# --------------------------------------------------------------------------------------------

if [ -f "$WALLPAPER" ]; then
    log info "Setting wallpaper using file: $WALLPAPER"
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        if command -v wallpaper >/dev/null 2>&1; then
            if wallpaper "$WALLPAPER"; then
                log success "Wallpaper set using wallpaper-cli."
            else
                log warn "Failed to set wallpaper using wallpaper-cli."
            fi
        else
            if osascript -e '
            tell application "System Events"
                set picture of every desktop to "'"$WALLPAPER"'"
            end tell'; then
                log success "Wallpaper set via AppleScript."
            else
                log warn "Failed to set wallpaper via AppleScript."
            fi
        fi
    elif [[ "$OS_TYPE" == "Linux" ]]; then
        log warn "Linux wallpaper setting not implemented. Skipped setting wallpaper file: $WALLPAPER"
    else
        log warn "Unsupported OS: $OS_TYPE. Skipped setting wallpaper."
    fi
else
    log warn "Wallpaper not found at $WALLPAPER"
fi

log celebrate "All done!"
