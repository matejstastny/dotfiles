# ██████╗  █████╗  █████╗ ██████╗ ██╗     ██╗███╗   ██╗███████╗    ███████╗███████╗██╗  ██╗██████╗  ██████╗
# ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║     ██║████╗  ██║██╔════╝    ╚══███╔╝██╔════╝██║  ██║██╔══██╗██╔════╝
# ██║  ██║███████║███████║██████╔╝██║     ██║██╔██╗ ██║███████╗      ███╔╝ ███████╗███████║██████╔╝██║
# ██║  ██║██╔══██║██╔══██║██╔══██╗██║     ██║██║╚██╗██║╚════██║     ███╔╝  ╚════██║██╔══██║██╔══██╗██║
# ██████╔╝██║  ██║██║  ██║██║  ██║███████╗██║██║ ╚████║███████║    ███████╗███████║██║  ██║██║  ██║╚██████╗
# ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝    ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝

# ---- Environment Variables ----
export APPDATA="$HOME/Library/Application Support"
export SDKMAN_DIR="$HOME/.sdkman"                             # Where SDKMAN stores SDK versions
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml" # Specifies the config file for the starship
export BAT_THEME="Dracula"
export PATH="$HOME/go/bin:$PATH" # Include go binaries in PATH

# ---- Shell Prompt Setup ----
eval "$(starship init zsh)"

# ---- Plugin Initialization ----
source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_HIGHLIGHT_STYLES[pre]="fg=magenta,underline"
ZSH_HIGHLIGHT_STYLES[arg0]="fg=magenta,bold"

# ---- SDKMAN Initialization ----
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

################################################################
# Aliases
################################################################

# General Aliases
alias n="clear && echo && fastfetch" # Clear screen, print newline, and run fastfetch
alias c="clear"                      # Clear the terminal screen
alias info="scc"                     # Run scc (sloc, complexity, and code) tool
alias cat="bat"                      # Use bat instead of cat for syntax highlighting

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
alias sign="sudo xattr -rd com.apple.quarantine" # Remove quarantine attribute to allow apps to run

# Tmux
alias tmain="attach_tmux_main"
alias q="tmux detach"

# Veracrypt
alias vc="veracrypt -t"

# Docker
alias dockerc="docker system prune --all --volumes"

################################################################
# Helper Functions
################################################################

attach_tmux_main() {
    if [[ "$TERM_PROGRAM" =~ (iTerm\.app|kitty|alacritty|WezTerm|ghostty) ]]; then
        if ! tmux has-session -t main 2>/dev/null; then
            tmux new-session -d -s main
        fi
        tmux attach -t main
    fi
}

################################################################
# Vulkan setup
################################################################

export VULKAN_SDK=~/VulkanSDK/1.4.321.0/macOS
export DYLD_LIBRARY_PATH=$VULKAN_SDK/lib:$DYLD_LIBRARY_PATH
export VK_ICD_FILENAMES=$VULKAN_SDK/etc/vulkan/icd.d/MoltenVK_icd.json
export VK_LAYER_PATH=$VULKAN_SDK/etc/vulkan/explicit_layer.d
export PATH=$VULKAN_SDK/bin:$PATH

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
