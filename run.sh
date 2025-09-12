#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------------------------------------
# run.sh — Configuration Installer
# --------------------------------------------------------------------------------------------
# Description:
#   This script runs individual installation scripts for linking dotfiles, installing Homebrew
#   packages, and installing assets. It accepts one or more arguments to run specific scripts.
# Usage:
#   ./run.sh [link|brew|assets|all]...
#   - link: Runs the linking script to create symlinks for dotfiles.
#   - brew: Runs the Homebrew installation and update script.
#   - assets: Runs the asset installation script.
#   - all (default): Runs all scripts in sequence.
# --------------------------------------------------------------------------------------------

line() {
    local char="${1:-—}"
    printf '%*s\n' "30" '' | tr ' ' "$char"
}

run_script() {
    local script_name="$1"
    local script_path="$2"
    echo "Starting $script_name script..."
    line
    "$script_path"
    echo ""
}

usage() {
    cat <<EOF
Usage: $0 [link|brew|assets|all]...
    - link   : Run the linking script to create symlinks for dotfiles.
    - brew   : Run the Homebrew installation and update script.
    - assets : Run the asset installation script.
    - all    : Run all scripts in sequence (default).
EOF
}

# --------------------------------------------------------------------------------------------
# Validate flags
# --------------------------------------------------------------------------------------------

if [ $# -eq 0 ]; then
    set -- all
fi

args=("$@")
for arg in "${args[@]}"; do
    if [ "$arg" = "all" ]; then
        set -- all
        break
    fi
done

for arg in "$@"; do
    case "$arg" in
    link | brew | assets | all) ;;
    *)
        usage
        exit 1
        ;;
    esac
done

# --------------------------------------------------------------------------------------------
# Run selected scripts
# --------------------------------------------------------------------------------------------

for arg in "$@"; do
    case "$arg" in
    link)
        run_script "link" ./scripts/link.sh
        ;;
    brew)
        run_script "brew" ./scripts/brew.sh
        ;;
    assets)
        run_script "assets" ./scripts/install_assets.sh
        ;;
    all)
        run_script "link" ./scripts/link.sh
        run_script "brew" ./scripts/brew.sh
        run_script "assets" ./scripts/install_assets.sh
        ;;
    esac
done

line
echo "All tasks completed!"
line
