#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/logging.sh"
source "$(dirname "$0")/config.sh"

# --------------------------------------------------------------------------------------------
# brew.sh — Homebrew Installer
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-08-19 (YYYY-MM-DD)
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------
# Description:
#   This script automates the setup and maintenance of Homebrew and its packages
#
# Actions performed:
#     1. Checks if Homebrew is installed; if not, installs it for the detected architecture
#     2. Updates Homebrew to fetch the latest formulae and casks
#     3. Upgrades all currently installed Homebrew packages to their latest versions
#     4. Installs additional packages as listed in a Brewfile, reporting on success or failure
#        of each package
#     5. Cleans up outdated versions and removes unnecessary files to free disk space
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
        error_exit "Homebrew update failed with error: $output"
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
            if [[ "$line" == Installing* ]]; then
                if [[ "$line" == *"has failed!" ]]; then
                    log error "$(awk '{print $2}' <<<"$line") installation failed"
                else
                    log success "Installing $(awk '{print $2}' <<<"$line")..."
                fi
            fi
            [[ "$line" == Using* ]] && log success-done "$(awk '{print $2}' <<<"$line") already installed"
        done <<<"$output"
        if [[ ${status:-0} -ne 0 ]]; then
            log warn "Some packages from Brewfile failed to install, continuing..."
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
log celebrate "All done!"
