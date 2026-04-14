#!/usr/bin/env bash
set -eu

DOTFILES_DIR="$HOME/dotfiles"

# Install Homebrewwww :3
if ! command -v brew >/dev/null 2>&1; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Python for my cushtom dot script
PYTHON=$(command -v python3 || true)
PYTHON_OK=false
if [ -n "$PYTHON" ]; then
	version=$("$PYTHON" -c 'import sys; print(sys.version_info >= (3, 11))' 2>/dev/null || echo False)
	[ "$version" = "True" ] && PYTHON_OK=true
fi
if [ "$PYTHON_OK" = false ]; then
	brew install python@3.11
fi

# Uhh.. the main thing the dotfiles :D
if [ ! -d "$DOTFILES_DIR" ]; then
	git clone https://github.com/matejstastny/dotfiles.git "$DOTFILES_DIR"
fi

# Its already executable, but just in case loll
chmod +x "$DOTFILES_DIR/bin/dot"
"$DOTFILES_DIR/bin/dot" all

echo "Done! Restart your terminal (>ω<)"
