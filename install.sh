#!/bin/bash

# Install xCode cli tools
if [[ "$(uname)" == "Darwin" ]]; then
    echo "MacOS detected, checking for Xcode tools..."

    if xcode-select -p &>/dev/null; then
        echo "Xcode already installed"
    else
        echo "Installing commandline tools..."
        xcode-select --install
    fi
fi

# Install Homebrew
echo "Installing Brew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew analytics off

## Formulae
echo "Installing Brew Formulae..."

### Must Have
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting
brew install stow
brew install bat
brew install btop
brew install scc
brew install fd
brew install zoxide
brew install eza
brew install prettier
brew install make
brew install gh
brew install npm

### Terminal
brew install git
brew install lazygit
brew install tmux
brew install neovim
brew install starship

## Casks
brew install --cask raycast
brew install --cask arc
brew install --cask visual-studio-code
brew install --cask wezterm
brew install --cask alacritty
brew install --cask ghostty

## Menubar
brew install --cask itsycal
brew install --cask hiddenbar

## MacOS settings
echo "Changing macOS defaults..."
defaults write com.apple.Dock autohide -bool TRUE
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write InitialKeyRepeat -int 10
defaults write com.apple.dock autohide-delay -float 0
killall Dock

csrutil status
echo "Installation complete..."

# Clone dotfiles repository
if [ ! -d "$HOME/.dotfiles" ]; then
    echo "Cloning dotfiles repository..."
    git clone https://github.com/kireiiiiiiii/dotfiles.git $HOME/.dotfiles
fi

# Navigate to dotfiles directory
cd $HOME/.dotfiles || exit

# Stow dotfiles packages
echo "Stowing dotfiles..."
stow --restow -t ~ .

# Fonts
echo "Installing fonts..."
if [ -d "$HOME/.dotfiles/assets/fonts/" ]; then
    find "$HOME/.dotfiles/assets/fonts/" -name "*.ttf" -o -name "*.otf" | while read -r font; do
        cp "$font" "$HOME/Library/Fonts/"
    done
    echo "Fonts installed."
else
    echo "No fonts directory found."
fi

# Wallpaper
echo "Installing npm package for wallpaper cli set..."
npm install --global wallpaper-cli
echo "Running command..."
wallpaper ~/.dotfiles/assets/wallpaper.png
echo "Wallpaper set"

echo "Dotfiles setup complete!"
