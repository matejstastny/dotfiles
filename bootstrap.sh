#!/usr/bin/env bash
set -eu

DOTFILES_DIR="$HOME/dotfiles"

if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [ ! -d "$DOTFILES_DIR" ]; then
    git clone https://github.com/matejstastny/dotfiles.git "$DOTFILES_DIR"
fi

chmod +x "$DOTFILES_DIR/bin/dot"
"$DOTFILES_DIR/bin/dot" all

echo "Done. Restart your terminal."
