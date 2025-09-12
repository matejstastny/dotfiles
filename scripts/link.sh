#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/logging.sh"

# --------------------------------------------------------------------------------------------
# link.sh — Minimal Dotfiles Linker
# --------------------------------------------------------------------------------------------
# Description:
#   This script creates symbolic links from your dotfiles repository to their proper locations
#   in your home directory or system-specific paths (e.g., VSCode User settings).
#   It functions similarly to GNU Stow, but is tailored for this repository's structure.
#
# Features:
#   - Safely link entire directories or individual files.
#   - Special handling for VSCode settings files.
#   - Prompts before overwriting existing files, with a --force option to skip prompts.
#   - Dry-run mode (--dry-run) to preview changes without modifying anything.
#   - Logging with clear emoji-based statuses: info, success, warning, error.
#
# Usage:
#   ./link.sh [--force] [--dry-run]
#
# Flags:
#   --force     : Overwrite all existing files without prompting.
#   --dry-run   : Show what would be linked without making changes.
#
# Notes:
#   - Ensure this script is executable: chmod +x link.sh
#   - Designed for macOS paths (especially the VSCode linking) but can work for Linux with
#     minor tweaks.
# --------------------------------------------------------------------------------------------

FORCE=false
DRY_RUN=false

declare -A EXCEPTIONS=(
    [zsh]="$HOME"
    [git]="$HOME"
    [rtorrent]="$HOME"
    [vscode]="$HOME/Library/Application Support/Code/User"
)

# --------------------------------------------------------------------------------------------
# Flags
# --------------------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
    --force) FORCE=true ;;
    --dry-run) DRY_RUN=true ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
    shift
done

# --------------------------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------------------------

prompt_or_force() {
    local prompt_msg="$1"
    if [ "$FORCE" = true ]; then
        return 0
    fi
    read -rp "$prompt_msg [y/N] " choice
    [[ "$choice" =~ ^[Yy]$ ]]
}

remove_target() {
    local target="$1"
    if $DRY_RUN; then
        log warn "Would remove existing $target"
    else
        rm -rf "$target"
        log warn "Removed existing $target"
    fi
}

link_symlink() {
    local src="$1"
    local tgt="$2"

    if [ -e "$tgt" ] || [ -L "$tgt" ]; then
        if [ -L "$tgt" ] && [ "$(readlink "$tgt")" = "$src" ]; then
            log success-done "$(basename "$tgt") already points to correct source"
            return
        fi
        if prompt_or_force "Target $tgt exists. Overwrite?"; then
            remove_target "$tgt"
        else
            log info "Skipped linking $tgt"
            return
        fi
    fi

    if $DRY_RUN; then
        log success "Would link $tgt -> $src"
    else
        ln -s "$src" "$tgt" && log success "Linked $tgt -> $src"
    fi
}

link_files() {
    local src_dir="$1"
    local tgt_dir="$2"
    mkdir -p "$tgt_dir"
    shopt -s dotglob nullglob
    for file in "$src_dir"/*; do
        [ -e "$file" ] || continue
        local filename
        filename="$(basename "$file")"
        link_symlink "$file" "$tgt_dir/$filename"
    done
    shopt -u dotglob nullglob
}

link_directory() {
    local src_dir="$1"
    local tgt_dir="$2"
    link_symlink "$src_dir" "$tgt_dir"
}

link_config() {
    local folder_name="$1"
    local src="$CONFIGS_DIR/$folder_name"

    if [[ -v EXCEPTIONS[$folder_name] ]]; then
        link_files "$src" "${EXCEPTIONS[$folder_name]}"
    else
        local tgt="$HOME/.config/$folder_name"
        link_directory "$src" "$tgt"
    fi
}

# --------------------------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------------------------

for folder in "$CONFIGS_DIR"/*; do
    [ -d "$folder" ] || continue
    folder_name="$(basename "$folder")"
    link_config "$folder_name"
done

log success "All configs linked!"
