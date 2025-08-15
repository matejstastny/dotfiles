# ██████╗  █████╗  █████╗ ██████╗ ██╗     ██╗███╗   ██╗███████╗    ███████╗███████╗██╗  ██╗██████╗  ██████╗
# ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║     ██║████╗  ██║██╔════╝    ╚══███╔╝██╔════╝██║  ██║██╔══██╗██╔════╝
# ██║  ██║███████║███████║██████╔╝██║     ██║██╔██╗ ██║███████╗      ███╔╝ ███████╗███████║██████╔╝██║
# ██║  ██║██╔══██║██╔══██║██╔══██╗██║     ██║██║╚██╗██║╚════██║     ███╔╝  ╚════██║██╔══██║██╔══██╗██║
# ██████╔╝██║  ██║██║  ██║██║  ██║███████╗██║██║ ╚████║███████║    ███████╗███████║██║  ██║██║  ██║╚██████╗
# ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝    ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝


# ---- Environment Variables ----
export APPDATA="$HOME/Library/Application Support"
export SDKMAN_DIR="$HOME/.sdkman" # Where SDKMAN stores SDK versions
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml" # Specifies the config file for the starship
export BAT_THEME="Dracula"
export PATH="$HOME/go/bin:$PATH" # Include go binaries in PATH

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
alias n="command clear && echo && command fastfetch"       # Clear screen, print newline, and run fastfetch
alias c="command clear"                                    # Clear the terminal screen
alias info="command scc"                                   # Run scc (sloc, complexity, and code) tool
alias cat="command bat"                                    # Use bat instead of cat for syntax highlighting

# Navigation
alias cd="command z"
alias ls="echo && command eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias lsa="echo && command eza --color=always --tree --git --no-filesize --icons=always --no-time --no-user --no-permissions"

# Java Version Management
alias java8="command sdk default java 8.0.432-amzn"
alias java21="command sdk default java 21.0.5-tem"

# Network Utilities
alias ip="command ifconfig | command grep 'inet ' | command awk '/inet / {print \$2}' | command grep -Ev '^(127\.|::)'"

# Security
alias sign="command sudo xattr -rd com.apple.quarantine"  # Remove quarantine attribute to allow apps to run

# Tmux
alias tmain="attach_tmux_main"                            # Function below
alias q="command tmux detach"

################################################################
# Helper Functions
################################################################

attach_tmux_main() {
    if [[ "$TERM_PROGRAM" =~ (iTerm\.app|kitty|alacritty|WezTerm|ghostty) ]]; then
        if ! command tmux has-session -t main 2>/dev/null; then
            command tmux new-session -d -s main
        fi
        command tmux attach -t main
    fi
}

################################################################
# Final Execution, KEEP AT THE END!
################################################################

eval "$(zoxide init zsh)"
attach_tmux_main

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/matejstastny/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
