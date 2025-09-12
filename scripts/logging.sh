#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------------------------------------
# logging.sh — Logging Functions
# --------------------------------------------------------------------------------------------
# Description:
#   This script provides logging functions with different levels (info, success, warn, error)
#   and corresponding emojis and colors for better readability in terminal output.
# --------------------------------------------------------------------------------------------

black=30
red=31
green=32
yellow=33
blue=34
purple=35
cyan=36
light_gray=37

log() {
    local level="$1"
    local msg="$2"
    local emoji color
    case "$level" in
    info)
        emoji="📦"
        color="$blue"
        ;;
    success)
        emoji="✅"
        color="$green"
        ;;
    success-done)
        emoji="☑️"
        color="$purple"
        ;;
    warn)
        emoji="⚠️"
        color="$yellow"
        ;;
    error)
        emoji="❌"
        color="$red"
        ;;
    *)
        emoji=" "
        color=""
        ;;
    esac
    [[ -z $color ]] || color="\033[${color}m"
    echo -e " ${color} ${emoji} ${msg}\033[0m"
}

error_exit() {
    if [ -n $2 ]; then
        log error "$1"
        exit $2
    else
        log error "$1"
        exit 1
    fi
}
