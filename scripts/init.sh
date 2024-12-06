#!/bin/bash

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}Starting setup for zsh environment on macOS...${NC}"

# Check for Homebrew and install if not found
if ! command -v brew &>/dev/null; then
  echo -e "${GREEN}Homebrew not found. Installing Homebrew...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)" # Ensure Homebrew is in the PATH
else
  echo -e "${GREEN}Homebrew is already installed.${NC}"
fi

# Update and upgrade Homebrew
echo -e "${GREEN}Updating and upgrading Homebrew...${NC}"
brew update && brew upgrade

# Install required tools via Homebrew
TOOLS=(
  git
  stow
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
  thefuck
  fzf
  bat
  exa
  tmux
  zoxide
  gh
	neovim
	neofetch
  fileicon
	lazygit
)

echo -e "${GREEN}Installing required tools via Homebrew...${NC}"
for tool in "${TOOLS[@]}"; do
  if brew list "$tool" &>/dev/null; then
    echo -e "${GREEN}$tool is already installed.${NC}"
  else
    brew install "$tool"
    echo -e "${GREEN}Installed $tool.${NC}"
  fi
done

# Install cask applications via Homebrew
CASK_APPS=(
  alacritty
  visual-studio-code
  font-hack-nerd-font
  oh-my-posh
	arc
)

echo -e "${GREEN}Installing required applications via Homebrew Cask...${NC}"
for app in "${CASK_APPS[@]}"; do
  if brew list --cask "$app" &>/dev/null; then
    echo -e "${GREEN}$app is already installed.${NC}"
  else
    brew install --cask "$app"
    echo -e "${GREEN}Installed $app.${NC}"
  fi
done

# Set custom icons using fileicon
ICON_DIR="$HOME/.custom-icons"

echo -e "${GREEN}Setting custom icons for applications...${NC}"
fileicon set /Applications/Alacritty.app "$ICON_DIR/alacritty.icns" && echo -e "${GREEN}Alacritty icon set successfully.${NC}"
fileicon set /Applications/Visual\ Studio\ Code.app "$ICON_DIR/vs-code.icns" && echo -e "${GREEN}VS Code icon set successfully.${NC}"

# Set up FZF keybindings and fuzzy completion
echo -e "${GREEN}Setting up FZF keybindings...${NC}"
"$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc

# Install Nerd Font
NERD_FONT="Hack"
FONT_DIR="$HOME/Library/Fonts"
if ! ls "$FONT_DIR" | grep -i "$NERD_FONT" &>/dev/null; then
  echo -e "${GREEN}Installing Nerd Font: $NERD_FONT...${NC}"
  brew install --cask font-hack-nerd-font
else
  echo -e "${GREEN}$NERD_FONT Nerd Font is already installed.${NC}"
fi

# Verify zsh is the default shell
if [ "$SHELL" != "$(which zsh)" ]; then
  echo -e "${GREEN}Changing default shell to zsh...${NC}"
  chsh -s "$(which zsh)"
else
  echo -e "${GREEN}zsh is already the default shell.${NC}"
fi

# Set up SDKMAN
if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  echo -e "${GREEN}Installing SDKMAN...${NC}"
  curl -s "https://get.sdkman.io" | bash
else
  echo -e "${GREEN}SDKMAN is already installed.${NC}"
fi

# Source SDKMAN script
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Final messages
echo -e "${GREEN}Setup complete! Restart your terminal to apply changes.${NC}"

