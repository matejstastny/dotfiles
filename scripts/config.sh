# --------------------------------------------------------------------------------------------
# config.sh — Configuration File for Dotfiles Installation Scripts
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-09-13 (YYYY-MM-DD)
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------
# Description:
#   This configuration file sets up essential environment variables and paths used by the
#   various installation scripts in the dotfiles repository.
# --------------------------------------------------------------------------------------------

ARCH=$(uname -m)
OS_TYPE="$(uname)"

DOTFILES_DIR="$HOME/dotfiles"
ASSETS_DIR="$DOTFILES_DIR/assets"
FONT_DIR="$ASSETS_DIR/fonts"
CONFIGS_DIR="$DOTFILES_DIR/configs"
WALLPAPER_DIR="$ASSETS_DIR/wallpapers"

BREWFILE="$DOTFILES_DIR/Brewfile"
WALLPAPER="$WALLPAPER_DIR/mac-wallpaper.jpg"
