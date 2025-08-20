#!/usr/bin/env bash
set -euo pipefail

# Variables
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGS_DIR="$REPO_ROOT/configs"
HOME_DIR="$HOME"

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
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') $emoji $msg"
}

# Function to link a single file or directory
link_file() {
  local src="$1"
  local tgt="$2"

  if [ -L "$tgt" ]; then
    if [ "$(readlink "$tgt")" = "$src" ]; then
      log info "Symlink exists and is correct: $tgt -> $src (skipping)"
      return
    else
      read -p "⚠️ $tgt is a symlink to $(readlink "$tgt"), overwrite with $src? [y/N] " choice
      if [[ "$choice" =~ ^[Yy]$ ]]; then
        rm -f "$tgt"
      else
        log info "Skipped overwriting $tgt"
        return
      fi
    fi
  elif [ -e "$tgt" ]; then
    read -p "⚠️ $tgt exists (not a symlink), overwrite with $src? [y/N] " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      rm -rf "$tgt"
    else
      log info "Skipped overwriting $tgt"
      return
    fi
  fi

  mkdir -p "$(dirname "$tgt")"

  if [ -d "$src" ]; then
    # Make sure we don't have an empty dir left at target
    [ -d "$tgt" ] && rmdir "$tgt" 2>/dev/null || true
  fi

  if ln -s "$src" "$tgt"; then
    log success "Linked $tgt -> $src"
  else
    log error "Failed to link $tgt -> $src"
  fi
}

link_config() {
  local config_folder="$1"
  local target_base="$2"
  # Loop over items in the config folder and link each as a whole
  for item in "$config_folder"/*; do
    [ -e "$item" ] || continue
    local base_item
    base_item="$(basename "$item")"
    local target="$target_base/$base_item"
    link_file "$item" "$target"
  done
}

for folder in "$CONFIGS_DIR"/*; do
  [ -d "$folder" ] || continue
  folder_name="$(basename "$folder")"
  # Link directly into $HOME
  if [[ "$folder_name" == "zsh" || "$folder_name" == "vscode"  || "$folder_name" == "git" ]]; then
    link_config "$folder" "$HOME_DIR"
  # Link into $HOME/.config/<folder_name>/
  else
    link_config "$folder" "$HOME_DIR/.config/$folder_name"
  fi
done

log success "All configs linked!"
