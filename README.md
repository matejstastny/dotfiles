![Banner](./assets/repo/banner.png)

```bash
# --------------------------------------------------------------------------------------------
# run.sh — Dotfiles Setup Orchestrator
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-09-12 (YYYY-MM-DD)
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------
# Description:
#   Orchestrates the execution of dotfiles setup scripts, such as linking configuration files,
#   installing Homebrew packages, and installing additional assets. The script validates all
#   arguments, and can run one or more specified tasks, or the special task "all" to perform
#   every setup step in sequence
#
# Usage:
#   ./run.sh [link|brew|assets|all]...
#   - link   : Run the linking script to create symlinks for dotfiles.
#   - brew   : Run the Homebrew installation and update script.
#   - assets : Run the asset installation script.
#   - all    : Run all scripts in sequence (default if no arguments provided).
#
#
# Examples:
#   ./run.sh brew assets
#   ./run.sh link
#   ./run.sh all
# --------------------------------------------------------------------------------------------
```

```bash
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
```

```bash
# --------------------------------------------------------------------------------------------
# install_assets.sh — Dotfiles Fonts and Wallpapers Installer
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-08-19 (YYYY-MM-DD)
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------
# Description:
#   This script automates the installation of fonts and the setting of wallpapers as part of
#   the dotfiles setup
#
# Actions performed:
#   1. OS Detection & Font Directory:
#       The script determines the appropriate target font directory based on the detected OS:
#         * On macOS (Darwin), it uses "$HOME/Library/Fonts"
#         * On Linux, it uses "$HOME/.local/share/fonts"
#         * On unsupported OSes, font installation is skipped
#
#   2. Font Installation:
#       On Linux and MacOS the script finds all .ttf and .otf files and copies them into the
#       target system font directory
#
#   3. Wallpaper Setting:
#       If the wallpaper file ($WALLPAPER) exists:
#         * On macOS: Attempts to use wallpaper-cli (https://github.com/sindresorhus/wallpaper-cli)
#           if available, otherwise falls back to AppleScript via osascript.
#         * On Linux: Wallpaper setting is not implemented
#         * On other OSes: Skipped
# --------------------------------------------------------------------------------------------
```

```bash
# --------------------------------------------------------------------------------------------
# link.sh — Minimal Dotfiles Linker
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-09-12 (YYYY-MM-DD)
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------
# Purpose:
#   This script automates the process of linking dotfiles from the repository into the home
#   directory or other system-specific locations. It ensures that configuration files are
#   properly symlinked, facilitating easy management and portability of your environment
#
# Repository Structure:
#   Assumes a CONFIGS_DIR containing subfolders for each configuration (e.g., zsh, git, vscode)
#   Each subfolder contains the relevant dotfiles or directories to be linked
#
# Exceptions:
#   Certain config folders (zsh, git, rtorrent, vscode) do not link the entire folder as a
#   symlink. Instead, their contents are linked individually to specified target directories:
#     - zsh, git, rtorrent: linked directly into $HOME
#     - vscode: linked into macOS-specific VSCode User settings directory
#
# Features:
#   - Links entire directories (except for exceptions)
#   - Handles existing files with prompts or forced overwrite
#   - Supports a dry-run mode to preview actions without making changes
#   - Logs operations with clear emoji-based status messages
#
# Usage:
#   ./link.sh [--force] [--dry-run]
#
# Examples:
#   ./link.sh
#       Prompts before overwriting existing files and links dotfiles.
#
#   ./link.sh --force
#       Overwrites all existing files without prompting.
#
#   ./link.sh --dry-run
#       Shows what would be linked without making any changes.
# --------------------------------------------------------------------------------------------
```
