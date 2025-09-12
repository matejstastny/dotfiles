#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------------------------------------
# install.sh — Dotfiles Bootstrap Installer
# --------------------------------------------------------------------------------------------
# Description:
#   This script clones the dotfiles repository (if needed) and runs the setup scripts:
#     1. Link dotfiles
#     2. Install Homebrew and packages via Brewfile
#     3. Install assets (fonts, wallpapers)
#
# Flags:
#   --force     : Skip prompts and overwrite existing files/packages
#   --dry-run   : Show actions without making changes
# --------------------------------------------------------------------------------------------

REPO_URL="https://github.com/matejstastny/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

FORCE=false
DRY_RUN=false

# --------------------------------------------------------------------------------------------
# Parse flags
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
# Logging helpers
# --------------------------------------------------------------------------------------------

log() {
    local level="$1"
    local msg="$2"
    local emoji color
    case "$level" in
    info)
        emoji="📦"
        color="\033[34m"
        ;;
    success)
        emoji="✅"
        color="\033[32m"
        ;;
    warn)
        emoji="⚠️"
        color="\033[33m"
        ;;
    error)
        emoji="❌"
        color="\033[31m"
        ;;
    *)
        emoji=" "
        color=""
        ;;
    esac
    echo -e " ${color}${emoji} ${msg}\033[0m"
}

line() {
    local char="${1:--}"
    local width
    width=$(tput cols 2>/dev/null || echo 80)
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

# --------------------------------------------------------------------------------------------
# Clone or update repository
# --------------------------------------------------------------------------------------------

clone_repo() {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        log info "Dotfiles repo already exists, pulling latest..."
        if ! git -C "$DOTFILES_DIR" pull --ff-only; then
            log warn "Failed to pull latest changes, continuing with existing repo"
        fi
    else
        log info "Cloning dotfiles repo to $DOTFILES_DIR..."
        if ! git clone "$REPO_URL" "$DOTFILES_DIR"; then
            log error "Failed to clone dotfiles repo"
            exit 1
        fi
    fi
}

# --------------------------------------------------------------------------------------------
# Run a script standalone, no flags
# --------------------------------------------------------------------------------------------

run_script() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")
    log info "Starting $script_name..."
    if ! "$script_path"; then
        log warn "Script $script_name failed."
        return 1
    fi
    log info "Finished $script_name."
    return 0
}

# --------------------------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------------------------

log info "Starting Dotfiles Bootstrap Installer"
line "="

clone_repo

source "$DOTFILES_DIR/scripts/config.sh"

declare -A script_status

for script in "$DOTFILES_DIR/scripts/link.sh" "$DOTFILES_DIR/scripts/brew.sh" "$DOTFILES_DIR/scripts/install_assets.sh"; do
    if run_script "$script"; then
        script_status["$(basename "$script")"]="success"
    else
        script_status["$(basename "$script")"]="fail"
    fi
done

line "="
log info "Summary of script execution:"
for script_name in "${!script_status[@]}"; do
    if [[ "${script_status[$script_name]}" == "success" ]]; then
        log success "$script_name: Success"
    else
        log warn "$script_name: Failed"
    fi
done
line "="

failures=0
for status in "${script_status[@]}"; do
    if [[ "$status" != "success" ]]; then
        ((failures++))
    fi
done

if [[ $failures -eq 0 ]]; then
    log success "Dotfiles bootstrap complete! All scripts ran successfully."
else
    log warn "Dotfiles bootstrap completed with $failures script(s) failing."
fi
