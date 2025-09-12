#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/logging.sh"
source "$(dirname "$0")/config.sh"

# --------------------------------------------------------------------------------------------
# brew.sh — Homebrew Installer
# --------------------------------------------------------------------------------------------
# Description:
#   This script installs Homebrew if not already installed, updates it, upgrades installed
#   packages, installs packages from a Brewfile, and cleans up.
# --------------------------------------------------------------------------------------------

install_homebrew() {
    log info "Checking for Homebrew..."
    if ! command -v brew >/dev/null 2>&1; then
        log info "Installing Homebrew..."
        if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            error_exit "Homebrew installation failed"
        fi
        if [[ $ARCH == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        log success-done "Homebrew is already installed"
    fi
}

update_homebrew() {
    log info "Updating Homebrew..."
    if output=$(brew update 2>&1); then
        if echo "$output" | grep -q "Already up-to-date"; then
            log success-done "Homebrew is already up-to-date"
        else
            log success "Homebrew updated successfully"
        fi
    else
        error_exit "Homebrew update failed"
    fi
}

upgrade_packages() {
    log info "Upgrading packages..."
    if output=$(brew upgrade 2>&1); then
        if [ -z "$output" ]; then
            log success-done "Packages already up-to-date"
        else
            log success "Packages upgraded successfully"
        fi
    else
        log warn "Some packages failed to upgrade, continuing..."
    fi
}

install_brewfile() {
    if [[ -f "$BREWFILE" ]]; then
        log info "Installing packages from Brewfile..."
        output=$(brew bundle --file="$BREWFILE" 2>&1) || status=$?
        while IFS= read -r line; do
            [[ "$line" == Installing* ]] && log success "$(awk '{print $2}' <<<"$line") installed"
            [[ "$line" == Using* ]] && log success-done "$(awk '{print $2}' <<<"$line") already installed"
        done <<<"$output"
        if [[ ${status:-0} -ne 0 ]]; then
            log warn "Some packages from Brewfile failed to install, continuing..."
            echo "$output"
        else
            log success "Brewfile packages installed successfully"
        fi
    else
        log error "Brewfile not found at $BREWFILE, skipping brew bundle"
    fi
}

cleanup() {
    log info "Cleaning up..."
    if ! brew cleanup >/dev/null 2>&1; then
        log warn "Cleanup failed, continuing..."
    fi
}

# --------------------------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------------------------

install_homebrew
update_homebrew
upgrade_packages
install_brewfile
cleanup
log success "All done!"
