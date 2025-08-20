#!/usr/bin/env bash

set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 🍺 Daarlin's Homebrew Setup Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect architecture
ARCH=$(uname -m)

# Install Homebrew if not installed
if ! command -v brew >/dev/null 2>&1; then
    echo "🔍 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for current shell
    if [[ $ARCH == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "✅ Homebrew is already installed"
fi

echo "🔄 Updating Homebrew..."
brew update

echo "📦 Upgrading installed packages..."
brew upgrade

# ========================
# Formulae
# ========================

FORMULAE=(
bat                         # Output files
btop                        # CLI activity monitor
create-dmg                  # For creating Java DMG's
curl                        # Download tool
docker
eza                         # Better ls
fastfetch                   # Neofetch
ffmpeg
fileicon                    # Set custom icons
fzf                         # Fuzzy finder
gh                          # GitHub CLI tool
git
git-delta                   # Syntax-highlighting pager for git and diff output
git-lfs                     # Large File Storage for Git
go
gradle
lazygit                     # Git UI
maven
neovim
proto                       # Protocol Buffers compiler (for Flaggi)
python
starship                    # Promt theme
stow                        # Dotfiles symlinks
scc                         # Info about source code
tmux
wget                        # Network downloader
zoxide                      # Better cd
zsh-syntax-highlighting
)

# ========================
# Casks
# ========================

CASKS=(
# Main apps
ghostty               # Main Terminal emulator
battery               # Tmux baterry indicator
chatgpt
mos                   # Scroll smoother
google-chrome
jordanbaird-ice       # Menu bar manager
iina                  # Video player
vesktop               # Discord
obsidian
visual-studio-code
wine-stable           # Windows emulator
)

echo "📥 Installing formulae..."
brew install "${FORMULAE[@]}"

echo "📥 Installing casks..."
brew install --cask "${CASKS[@]}"

echo "🧹 Cleaning up..."
brew cleanup

echo "✅ All done!"
