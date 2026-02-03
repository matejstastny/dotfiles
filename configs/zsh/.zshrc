# --------------------------------------------------------------------------------------------
# .zshrc - my zsh configuration file
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-03-02 (YYYY-MM-DD)
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------

# Aliases ------------------------------------------------------------------------------------

alias d='trash'
alias c='clear'
alias info='scc'

alias cd='z'
alias ls='echo && eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
alias lsa='echo && eza --color=always --long --git --icons=always'
alias lsaa='echo && eza --color=always --long --git --icons=always -a'
alias lst='echo && eza --color=always --tree --git --no-filesize --icons=always --no-time --no-user --no-permissions'

alias ip="ifconfig | grep 'inet ' | awk '/inet / {print \$2}' | grep -Ev '^(127\.|::)'"
alias sign='sudo xattr -rd com.apple.quarantine'

alias q='tmux detach'
alias qa='tmux kill-server'

alias vc='veracrypt -t'
alias dockerc='docker system prune --all --volumes'

alias n='clear && fastfetch -c $HOME/.config/fastfetch/themes/cat.jsonc'
alias nm='clear && fastfetch -c $HOME/.config/fastfetch/themes/fastcat.jsonc'
alias nd='clear && fastfetch -c $HOME/.config/fastfetch/themes/detailed.jsonc'
alias nj='clear && fastfetch -c $HOME/.config/fastfetch/themes/jellyfish.jsonc'

# Prompt & Plugins ---------------------------------------------------------------------------

# Starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

# Zoxide
eval "$(zoxide init zsh)"

# Zsh autosuggestions
source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Zsh syntax highlighting
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_HIGHLIGHT_STYLES[command]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=blue,bold'

# Bat
BAT_THEME="tokyonight_night"
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# Fzf
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND="find -L"

# Jenv
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# Completions ---------------------------------------------------------------------------------

fpath=($HOME/.docker/completions $fpath)

autoload -Uz compinit
compinit

# Completion settings
zstyle ':completion:*' menu select
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' list-colors "$LS_COLORS" ma=0\;33
zstyle ':completion:*' squeeze-slashes false

# Shell Options ------------------------------------------------------------------------------

setopt append_history inc_append_history share_history
setopt auto_menu menu_complete
setopt autocd
setopt auto_param_slash
setopt no_case_glob no_case_match
setopt globdots
setopt extended_glob
setopt interactive_comments
unsetopt prompt_sp
stty stop undef
bindkey -e

# History ------------------------------------------------------------------------------------

HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE="$XDG_CACHE_HOME/zsh_history"
HISTCONTROL=ignoreboth

if [[ -n $TMUX_PANE ]]; then
    HISTDIR="$HOME/.zsh_tmux_hist"
    mkdir -p "$HISTDIR"
    HISTFILE="$HISTDIR/.zsh_history_${TMUX_PANE:1}"
    if [[ ! -f $HISTFILE ]]; then
        cp "$HOME/.zsh_history" "$HISTFILE" 2>/dev/null
    fi
fi

# Init ---------------------------------------------------------------------------------------

(clear && fastfetch -c $HOME/.config/fastfetch/themes/cat.jsonc) 2>/dev/null
