# --------------------------------------------------------------------------------------------
# .zshrc - my zsh configuration file
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-03-02 (YYYY-MM-DD)
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------

# Custom env vars ----------------------------------------------------------------------------

export APP_DATA="$HOME/Library/Application Support"

# Aliases ------------------------------------------------------------------------------------

alias n="clear && echo && fastfetch"
alias c="clear"
alias info="scc"
alias cat="bat --paging=never"

alias cd="z"
alias ls="echo && eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias lsa="echo && eza --color=always --tree --git --no-filesize --icons=always --no-time --no-user --no-permissions"

alias java21="sdk default java 21.0.5-tem"
alias java8="sdk default java 8.0.432-amzn"

alias ip="ifconfig | grep 'inet ' | awk '/inet / {print \$2}' | grep -Ev '^(127\.|::)'"
alias sign="sudo xattr -rd com.apple.quarantine"

alias q="tmux detach"
alias qa="tmux kill-server"

alias vc="veracrypt -t"
alias dockerc="docker system prune --all --volumes"

# Global functions ---------------------------------------------------------------------------

tmain() {
    if ! tmux has-session -t main 2>/dev/null; then
        tmux new-session -d -s main
    fi
    tmux attach -t main
}

# Initialization -----------------------------------------------------------------------------

# starship prompt
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

# zoxide
eval "$(zoxide init zsh)"

# sdkman
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# zsh autosuggestions
source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh syntax highlighting
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_HIGHLIGHT_STYLES[pre]="fg=magenta,underline"
ZSH_HIGHLIGHT_STYLES[arg0]="fg=magenta,bold"

# Bat
export BAT_THEME="gruvbox-dark"
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# Go
export PATH="$HOME/go/bin:$PATH"

# Proto
export PROTO_HOME="$HOME/.proto"
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"

# Vulkan
export VULKAN_SDK=~/VulkanSDK/1.4.321.0/macOS
export DYLD_LIBRARY_PATH=$VULKAN_SDK/lib:$DYLD_LIBRARY_PATH
export VK_ICD_FILENAMES=$VULKAN_SDK/etc/vulkan/icd.d/MoltenVK_icd.json
export VK_LAYER_PATH=$VULKAN_SDK/etc/vulkan/explicit_layer.d
export PATH=$VULKAN_SDK/bin:$PATH

# Docker
fpath=(/Users/matejstastny/.docker/completions $fpath)
autoload -Uz compinit
compinit

# Attach to tmux -----------------------------------------------------------------------------

[[ "$TERM_PROGRAM" =~ "ghostty" ]] && tmain
