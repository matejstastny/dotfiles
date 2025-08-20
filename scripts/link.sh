#!/usr/bin/env bash
set -euo pipefail

# Variables ------------------------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGS_DIR="$REPO_ROOT/configs"
HOME_DIR="$HOME"

# Logging --------------------------------------------------------------------------------------------

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

# Helpers --------------------------------------------------------------------------------------------

check_parent_symlinks() {
    local tgt="$1"
    local current="$tgt"
    while [ "$current" != "/" ]; do
        current="$(dirname "$current")"
        if [ -L "$current" ]; then
            read -p "⚠️ Parent path $current is a symlink, delete it? [y/N] " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                rm -rf "$current"
                log success "Removed parent symlink"
            else
                log info "Skipped linking $(basename "$current")"
                return 1
            fi
            break
        fi
    done
    return 0
}

link_file() {
    local src="$1"
    local tgt="$2"

    if [ -L "$tgt" ]; then
        if [ "$(readlink "$tgt")" = "$src" ]; then
            log success "Symlink exists and is correct"
            return 0
        else
            echo "⚠️ $tgt is a symlink to $(readlink "$tgt")"
            read -p "   Overwrite with $src? [y/N] " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                rm -f "$tgt"
            else
                log info "Skipped overwriting $(basename "$tgt")"
                return 0
            fi
        fi
    elif [ -e "$tgt" ]; then
        read -p "⚠️ $tgt exists (not a symlink), overwrite with $src? [y/N] " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            rm -rf "$tgt"
        else
            log info "Skipped overwriting $tgt"
            return 0
        fi
    fi

    check_parent_symlinks "$tgt" || return 0
    mkdir -p "$(dirname "$tgt")"

    if [ -d "$src" ]; then
        [ -d "$tgt" ] && rmdir "$tgt" 2>/dev/null || true
    fi

    if ln -s "$src" "$tgt"; then
        log info "Linked $tgt"
    else
        log error "Failed to link $tgt -> $src"
    fi
}

# Methods --------------------------------------------------------------------------------------------

link_config() {
    local config_folder="$1"
    local target_base="$2"
    log info "Creating symlinks for $(basename "$config_folder")"

    shopt -s nullglob dotglob # make globbing behave correctly, include hidden files
    local items=("$config_folder"/*)
    shopt -u nullglob dotglob

    if [ ${#items[@]} -eq 0 ]; then
        log warn "No files found in $config_folder"
        return
    fi

    for item in "${items[@]}"; do
        local base_item
        base_item="$(basename "$item")"
        local target="$target_base/$base_item"
        link_file "$item" "$target"
    done
    log success "Linked $(basename "$config_folder")"
}

# Main script ----------------------------------------------------------------------------------------

for folder in "$CONFIGS_DIR"/*; do
    [ -d "$folder" ] || continue
    folder_name="$(basename "$folder")"
    if [[ "$folder_name" == "zsh" || "$folder_name" == "git" ]]; then
        link_config "$folder" "$HOME_DIR"
    elif [[ "$folder_name" == "vscode" ]]; then
        link_config "$folder" "$HOME/Library/Application Support/Code/User"
        continue
    else
        link_config "$folder" "$HOME_DIR/.config/$folder_name"
    fi
done

log success "All configs linked!"
