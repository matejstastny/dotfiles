#!/usr/bin/env zsh

# --------------------------------------------------------------------------------------------
# .zprofile - zsh login shell configuration (session-wide)
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-09-12
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------

# 🖥️ Defaults -------------------------------------------------------------------------------

export EDITOR="nvim"
export TERM="ghostty"
export TERMINAL="ghostty"
export BROWSER="firefox"

# 🌐 Locale ---------------------------------------------------------------------------------

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# 📂 XDG Base Directories -------------------------------------------------------------------

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# 📦 Environment Variables -------------------------------------------------------------------

export APP_DATA="$HOME/Library/Application Support"

# ☕ SDKs ------------------------------------------------------------------------------------

export GOPATH="$HOME/go"
export PROTO_HOME="$HOME/.proto"

# 🐉 Vulkan SDK -----------------------------------------------------------------------------

export VULKAN_SDK="$HOME/VulkanSDK/1.4.321.0/macOS"
export DYLD_LIBRARY_PATH="$VULKAN_SDK/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
export VK_ICD_FILENAMES="$VULKAN_SDK/etc/vulkan/icd.d/MoltenVK_icd.json"
export VK_LAYER_PATH="$VULKAN_SDK/etc/vulkan/explicit_layer.d"

# ☕ sdkman ----------------------------------------------------------------------------------

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# If SDKMAN Java is set, export JAVA_HOME session-wide
if [[ -n "$SDKMAN_CANDIDATES_DIR" && -d "$SDKMAN_CANDIDATES_DIR/java/current" ]]; then
    export JAVA_HOME="$SDKMAN_CANDIDATES_DIR/java/current"
fi

# 🔍 fzf defaults ---------------------------------------------------------------------------

export FZF_DEFAULT_OPTS="--style minimal --color 16 --layout=reverse --height 30% --preview='bat -p --color=always {}'"
export FZF_CTRL_R_OPTS="--style minimal --color 16 --info inline --no-sort --no-preview"
export MANPAGER="less -R --use-color -Dd+r -Du+b"

# 🍺 Homebrew ------------------------------------------------------------------------------

eval "$(/opt/homebrew/bin/brew shellenv)"

# 🛣️ PATH setup -----------------------------------------------------------------------------

typeset -U path
path=(
    "$HOME/bin"
    "$GOPATH/bin"
    "$VULKAN_SDK/bin"
    "/opt/homebrew/bin"
    "$PROTO_HOME/shims"
    "$PROTO_HOME/bin"
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    $path
)
