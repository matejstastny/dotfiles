#!/usr/bin/env bash

set -eu
source "$(dirname "$0")/logging.sh"

# Install/update tokyo night theme for bat
log info "Installing tokyo-night for bat..."
"$HOME/dotfiles/configs/bat/bat-into-tokyonight/bat-into-tokyonight"

log celebrate "All done!"
