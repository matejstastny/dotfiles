#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/logging.sh"

# --------------------------------------------------------------------------------------------
# link.sh — Minimal Dotfiles Linker
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-09-12 (YYYY-MM-DD)
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------
# Purpose:
#   This script automates the process of linking dotfiles from the repository into the home
#   directory or other system-specific locations. It ensures that configuration files are
#   properly symlinked, facilitating easy management and portability of your environment
#
# Repository Structure:
#   Assumes a CONFIGS_DIR containing subfolders for each configuration (e.g., zsh, git, vscode)
#   Each subfolder contains the relevant dotfiles or directories to be linked
#
# Exceptions:
#   Certain config folders (zsh, git, rtorrent, vscode) do not link the entire folder as a
#   symlink. Instead, their contents are linked individually to specified target directories:
#     - zsh, git, rtorrent: linked directly into $HOME
#     - vscode: linked into macOS-specific VSCode User settings directory
#
# Features:
#   - Links entire directories (except for exceptions)
#   - Handles existing files with prompts or forced overwrite
#   - Supports a dry-run mode to preview actions without making changes
#   - Logs operations with clear emoji-based status messages
#
# Usage:
#   ./link.sh [--force] [--dry-run]
#
# Examples:
#   ./link.sh
#       Prompts before overwriting existing files and links dotfiles.
#
#   ./link.sh --force
#       Overwrites all existing files without prompting.
#
#   ./link.sh --dry-run
#       Shows what would be linked without making any changes.
# --------------------------------------------------------------------------------------------

FORCE=false
DRY_RUN=false

# Directories that should be linked as whole directories to custom locations
declare -A DIR_EXCEPTIONS=()

# Directories whose contents should be linked file-by-file to custom locations
declare -A FILE_EXCEPTIONS=(
    [zsh]="$HOME"
    [git]="$HOME"
    [vscode]="$HOME/Library/Application Support/Code/User"
    [vesktop]="$HOME/Library/Application Support/vesktop/themes"
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
    read -rp "$(log prompt "$prompt_msg") [y/N] " choice
    [[ "$choice" =~ ^[Yy]$ ]]
}

remove_target() {
    local target="$1"
    if $DRY_RUN; then
        log warn "Would remove existing $target"
    else
        rm -rf "$target"
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

    if [[ -v FILE_EXCEPTIONS[$folder_name] ]]; then
        link_files "$src" "${FILE_EXCEPTIONS[$folder_name]}"
    elif [[ -v DIR_EXCEPTIONS[$folder_name] ]]; then
        link_directory "$src" "${DIR_EXCEPTIONS[$folder_name]}"
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

log celebrate "All done!"
