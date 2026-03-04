#!/usr/bin/env bash

set -eu
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

if [[ "$OS_TYPE" == "Darwin" ]]; then
    TARGET_FONT_DIR="$HOME/Library/Fonts"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    TARGET_FONT_DIR="$HOME/.local/share/fonts"
else
    log warn "Unsupported OS: $OS_TYPE. Font installation skipped."
    TARGET_FONT_DIR=""
fi

# Fonts --------------------------------------------------------------------------------------

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
                target_font="$TARGET_FONT_DIR/$(basename "$font")"
                if [[ -f "$target_font" ]]; then
                    log success-done "Font already exists: $(basename "$font")"
                else
                    if cp "$font" "$TARGET_FONT_DIR/"; then
                        log success "Installed font: $(basename "$font")"
                    else
                        log warn "Failed to install font: $(basename "$font")"
                    fi
                fi
            done
        else
            log warn "No font files found in $FONT_DIR."
        fi
    else
        log warn "No fonts directory found at $FONT_DIR."
    fi
fi

# Wallpaper ----------------------------------------------------------------------------------

if [[ "$OS_TYPE" == "Darwin" ]]; then
    if [ ! -f "$WALLPAPER" ]; then
        log_fatal "Wallpaper not found at $WALLPAPER"
    fi
    log info "Setting wallpaper using file: $WALLPAPER"
    if osascript -e '
        tell application "System Events"
            set picture of every desktop to "'"$WALLPAPER"'"
        end tell'; then
        log success "Wallpaper set via AppleScript."
    else
        log warn "Failed to set wallpaper via AppleScript."
    fi
elif [[ "$OS_TYPE" == "Linux" ]]; then
    log info "On Linux, wallpaper is managed by hyprpaper via ~/.config/hyprpaper/hyprpaper.conf"
    log info "Edit configs/hyprpaper/hyprpaper.conf to set your wallpaper path."
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl hyprpaper wallpaper ",${WALLPAPER}" 2>/dev/null && log success "Wallpaper applied via hyprpaper." || true
    fi
fi

log celebrate "All done!"
