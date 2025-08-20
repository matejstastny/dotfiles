![Banner](./assets/repository/banner.png)

```txt
# --------------------------------------------------------------------------------------------
# brew.sh — Homebrew Installer
# --------------------------------------------------------------------------------------------
# Description:
#   This script installs Homebrew on macOS if it's not already installed, updates it, upgrades
#   existing packages, and installs a predefined list of formulae and casks.
#
# Features:
#   - Installs Homebrew if missing
#   - Updates and upgrades Homebrew packages
#   - Installs formulae and casks from predefined lists
#   - Logs progress with emojis for info, success, warning, and error
#   - Cleans up outdated Homebrew packages
#
# Usage:
#   ./brew.sh
#
# Notes:
#   - Ensure this script is executable: chmod +x brew.sh
#   - Suppresses normal brew output, only logs errors and progress
#   - Compatible with both Intel (x86_64) and Apple Silicon (arm64) Macs
# --------------------------------------------------------------------------------------------
```

```txt
# --------------------------------------------------------------------------------------------
# install_assets.sh — Dotfiles Assets Installer
# --------------------------------------------------------------------------------------------
# Description:
#   This script installs fonts, wallpapers, and clones this dotfiles repository.
#
# Usage:
#   install_assets.sh
#
# Notes:
#   - Ensure this script is executable: chmod +x install_assets.sh
# --------------------------------------------------------------------------------------------
```

```txt
# --------------------------------------------------------------------------------------------
# link.sh — Minimal Dotfiles Linker
# --------------------------------------------------------------------------------------------
# Description:
#   This script creates symbolic links from your dotfiles repository to their proper locations
#   in your home directory or system-specific paths (e.g., VSCode User settings).
#   It functions similarly to GNU Stow, but is tailored for this repository's structure.
#
# Features:
#   - Safely link entire directories or individual files.
#   - Special handling for VSCode settings files.
#   - Prompts before overwriting existing files, with a --force option to skip prompts.
#   - Dry-run mode (--dry-run) to preview changes without modifying anything.
#   - Logging with clear emoji-based statuses: info, success, warning, error.
#
# Usage:
#   ./link.sh [--force] [--dry-run]
#
# Flags:
#   --force     : Overwrite all existing files without prompting.
#   --dry-run   : Show what would be linked without making changes.
#
# Notes:
#   - Ensure this script is executable: chmod +x link.sh
#   - Designed for macOS paths (especially the VSCode linking) but can work for Linux with
#     minor tweaks.
# --------------------------------------------------------------------------------------------
```
