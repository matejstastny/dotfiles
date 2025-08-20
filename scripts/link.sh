#!/usr/bin/env bash
set -euo pipefail

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

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGS_DIR="$REPO_ROOT/configs"
HOME_DIR="$HOME"

FORCE=false
DRY_RUN=false

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
# Logging
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
# Helpers
# --------------------------------------------------------------------------------------------

prompt_or_force() {
    local prompt_msg="$1"
    if [ "$FORCE" = true ]; then
        return 0
    fi
    read -p "$prompt_msg [y/N] " choice
    [[ "$choice" =~ ^[Yy]$ ]]
}

link_directory() {
    local src="$1"
    local tgt="$2"

    if [ -e "$tgt" ] || [ -L "$tgt" ]; then
        if [ -L "$tgt" ]; then
            local current_target
            current_target="$(readlink "$tgt")"
            if [ "$current_target" = "$src" ]; then
                log info "Link for $(basename "$src") already points to correct source, skipping"
                return
            fi
        fi
        if prompt_or_force "Target $tgt exists. Overwrite?"; then
            $DRY_RUN || rm -rf "$tgt"
            log warn "Removed existing $tgt"
        else
            log info "Skipped linking $tgt"
            return
        fi
    fi

    if $DRY_RUN; then
        log info "Would link $tgt -> $src"
    else
        ln -s "$src" "$tgt" && log success "Linked $tgt -> $src"
    fi
}

link_vscode_files() {
    local src="$CONFIGS_DIR/vscode"
    local tgt="$HOME/Library/Application Support/Code/User"
    mkdir -p "$tgt"
    for file in "$src"/*; do
        [ -e "$file" ] || continue
        local filename
        filename="$(basename "$file")"
        local target_file="$tgt/$filename"

        if [ -e "$target_file" ] || [ -L "$target_file" ]; then
            if [ -L "$target_file" ]; then
                local current_target
                current_target="$(readlink "$target_file")"
                if [ "$current_target" = "$file" ]; then
                    log info "Link $target_file already points to $file, skipping"
                    continue
                fi
            fi
            if prompt_or_force "Target $target_file exists. Overwrite?"; then
                $DRY_RUN || rm -rf "$target_file"
                log warn "Removed existing $target_file"
            else
                log info "Skipped linking $target_file"
                continue
            fi
        fi

        if $DRY_RUN; then
            log info "Would link $target_file -> $file"
        else
            ln -s "$file" "$target_file" && log success "Linked $target_file -> $file"
        fi
    done
}

link_config() {
    local folder_name="$1"
    local src="$CONFIGS_DIR/$folder_name"
    local tgt

    case "$folder_name" in
    zsh | git) tgt="$HOME_DIR/$folder_name" ;;
    vscode) tgt="$HOME/Library/Application Support/Code/User" ;;
    *) tgt="$HOME_DIR/.config/$folder_name" ;;
    esac

    if [ "$folder_name" = "vscode" ]; then
        link_vscode_files
    else
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
