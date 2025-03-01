################################################################
# Zsh Configuration
################################################################

# ---- Environment Variables ----
export APPDATA="$HOME/Library/Application Support"
export SDKMAN_DIR="$HOME/.sdkman"
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
export BAT_THEME="Dracula"
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"

# ---- Shell Prompt Setup ----
eval "$(starship init zsh)"

# ---- Plugin Initialization ----
source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_HIGHLIGHT_STYLES[precommand]="fg=magenta,underline"
ZSH_HIGHLIGHT_STYLES[arg0]="fg=magenta,bold"

# ---- SDKMAN Initialization ----
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

################################################################
# Aliases
################################################################

# General Aliases
alias n="clear && echo && command fastfetch"
alias c="clear"
alias help="tldr"
alias info="scc"
alias cat="bat"

# Navigation
alias cd="z"
alias ls="echo && eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias lsa="echo && eza --color=always --tree --git --no-filesize --icons=always --no-time --no-user --no-permissions"

# Java Version Management
alias java8="sdk default java 8.0.432-amzn"
alias java21="sdk default java 21.0.5-tem"

# Network Utilities
alias ip="ifconfig | grep 'inet ' | awk '/inet / {print \$2}' | grep -Ev '^(127\.|::)'"

# Security
alias sign="sudo xattr -rd com.apple.quarantine"

# Command Correction
eval "$(thefuck --alias)"

# Tmux
alias tmain="attach_tmux_main"
alias q="tmux detach"

################################################################
# Helper Functions
################################################################

attach_tmux_main() {
    if [[ "$TERM_PROGRAM" =~ (iTerm\.app|kitty|alacritty|WezTerm) ]]; then
        if ! tmux has-session -t main 2>/dev/null; then
            tmux new-session -d -s main
        fi
        tmux attach -t main
    fi
}

################################################################
# Final Execution, KEEP AT THE END!
################################################################

eval "$(zoxide init zsh)"
attach_tmux_main
