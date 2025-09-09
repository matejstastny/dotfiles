#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------------------------------------
# brew.sh — Homebrew Installer
# --------------------------------------------------------------------------------------------
# Description:
#   This script installs Homebrew on macOS if it's not already installed, updates it, upgrades
#   existing packages, and installs a predefined list of formulae and casks.
#
# Features:
#   - Installs Homebrew if missing
#   - Updates and upgrades Homebrew packages
#   - Installs formulae and casks from predefined lists
#   - Logs progress with emojis for info, success, warning, and error
#   - Cleans up outdated Homebrew packages
#
# Usage:
#   ./brew.sh
#
# Notes:
#   - Ensure this script is executable: chmod +x brew.sh
#   - Suppresses normal brew output, only logs errors and progress
#   - Compatible with both Intel (x86_64) and Apple Silicon (arm64) Macs
# --------------------------------------------------------------------------------------------

IFS=$'\n\t'
ARCH=$(uname -m)
OUTPUT=""

# --------------------------------------------------------------------------------------------
# Logging
# --------------------------------------------------------------------------------------------

log() {
    local level="$1"
    local msg="$2"
    local emoji color
    case "$level" in
    info)
        emoji="📋"
        color=""
        ;; # Cyan
    done)
        emoji="📦"
        color="\033[36m"
        ;; # Cyan
    success)
        emoji="✅"
        color="\033[32m"
        ;; # Green
    warn)
        emoji="⚠️"
        color="\033[33m"
        ;; # Yellow
    error)
        emoji="❌"
        color="\033[31m"
        ;; # Red
    *)
        emoji=""
        color="\033[0m"
        ;;
    esac
    echo -e " ${color} ${emoji} ${msg}\033[0m"
}

error_exit() {
    if [ -n $2 ]; then
        log error "$1"
        exit $2
    else
        log error "$1"
        exit 1
    fi
}

# --------------------------------------------------------------------------------------------
# Homebrew installation
# --------------------------------------------------------------------------------------------

if ! command -v brew >/dev/null 2>&1; then
    log info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" ||
        error_exit "Homebrew installation failed"

    if [[ $ARCH == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    log success "Homebrew is already installed"
fi

log info "Updating Homebrew..."
if OUTPUT=$(brew update 2>&1); then
    if echo "$OUTPUT" | grep -q "Already up-to-date"; then
        log done "Homebrew is already up-to-date"
    else
        log success "Homebrew updated successfully"
    fi
else
    error_exit "Homebrew update failed" 11
fi

log info "Upgrading packages..."
if OUTPUT=$(brew upgrade 2>&1); then
    if [ -z "$OUTPUT" ]; then
        log done "No packages to upgrade"
    else
        log success "Packages upgraded successfully"
    fi
else
    log warn "Some packages failed to upgrade, continuing..."
fi

# --------------------------------------------------------------------------------------------
# Formulae & Casks
# --------------------------------------------------------------------------------------------

FORMULAE=(
    bash bat btop create-dmg curl docker eza fastfetch ffmpeg fileicon fzf gh git git-delta git-lfs go
    gradle lazygit maven neovim proto python starship stow scc tmux wget zoxide zsh-syntax-highlighting
)

CASKS=(
    ghostty battery chatgpt mos google-chrome jordanbaird-ice iina vesktop obsidian
    visual-studio-code wine-stable
)

install_packages() {
    local packages=("$@")
    for pkg in "${packages[@]}"; do
        if brew list "$pkg" >/dev/null 2>&1 || brew list --cask "$pkg" >/dev/null 2>&1; then
            log success "$pkg already installed"
        else
            log info "Installing $pkg..."
            brew install "$pkg" 2>/dev/null || brew install --cask "$pkg" 2>/dev/null ||
                log warn "Failed to install $pkg, continuing..."
        fi
    done
}

log info "Installing formulae..."
install_packages "${FORMULAE[@]}"

log info "Installing casks..."
install_packages "${CASKS[@]}"

log info "Cleaning up..."
brew cleanup >/dev/null || log warn "Cleanup failed, continuing..."

log success "All done!"
