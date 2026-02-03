#!/usr/bin/env bash

set -eu
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

brew_failed() { log_fatal "Homebrew command failed!"; }

# Check for brew
if ! command -v brew >/dev/null 2>&1; then
    error_exit "Homebrew not installed!"
fi

# Update brew
log info "Updating Homebrew..."
brew update -q || brew_failed

# Update packages
log info "Upgrading packages..."
brew upgrade -q || brew_failed

# brewfile
if [[ ! -f "$BREWFILE" ]]; then
    error_exit "Brewfile not found at $BREWFILE!"
fi

log info "Installing packages from Brewfile..."
brew bundle --file="$BREWFILE" -q || brew_failed

log info "Uninstalling stuff not defined in Brefile..."
brew bundle cleanup --file="$BREWFILE" --force -q || brew_failed

# cleanup
log info "Cleaning up..."
brew cleanup || brew_failed

log celebrate "All done!"
