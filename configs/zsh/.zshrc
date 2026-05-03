# Prevent duplicate init when this file is sourced from multiple startup files
if [[ -n ${ZSHRC_LOADED_ONCE:-} ]]; then
    return
fi
ZSHRC_LOADED_ONCE=1

# Env variables ------------------------------------------------------------------------------

# Defaults
export EDITOR="nvim"
export BROWSER="firefox"
export DOTFILES_DIR="$HOME/dotfiles"

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# XDG Base
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# fzf config
export FZF_DEFAULT_OPTS="--style minimal --color 16 --layout=reverse --height 30% --preview='bat -p --color=always {}'"
export FZF_CTRL_R_OPTS="--style minimal --color 16 --info inline --no-sort --no-preview"

# sdk config
export GOPATH="$HOME/go"
export PROTO_HOME="$HOME/.proto"
export BUN_INSTALL="$HOME/.bun"

# sdkman config
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

# asahi fedora hyprland
export APP_DATA="$XDG_DATA_HOME"
export MOZ_ENABLE_WAYLAND=1

# path
typeset -U path
path=(
    "$HOME/dotfiles/bin"
    "$HOME/bin/bin"
    "$HOME/.local/bin"
    "$GOPATH/bin"
    $path
)

# Aliases ------------------------------------------------------------------------------------

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias cd='z'
alias dots='cd ~/dotfiles'
alias scr='ls ~/bin/bin'

# Git
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gp='git push'
alias gs='git status -sb'
alias lg='lazygit'

# System
alias c='clear'
alias copy='wl-copy'
alias paste='wl-paste'
alias localip="ip -4 addr show | awk '/inet / && !/127.0.0/ {print \$2}'"
alias n='clear && fastfetch'
alias nocolor='sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g"'
alias path='echo $PATH | tr ":" "\n"'
alias ports='ss -tlnp'

# Tools
alias aria='aria2c'
alias dockerc='docker system prune --all --volumes'
alias nv='nvim'

# Listing
alias ls='echo && eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
alias lsa='echo && eza --color=always --long --git --icons=always'
alias lsaa='echo && eza --color=always --long --git --icons=always -a'
alias lst='echo && eza --color=always --tree --git --no-filesize --icons=always --no-time --no-user --no-permissions'

# Tmux
alias q='tmux detach'
alias qa='tmux kill-server'
alias tl='tmux display-message -p "#{window_layout}"'

# Agents
alias cc='clear && claude --dangerously-skip-permissions'
alias ccc='clear && claude --dangerously-skip-permissions --continue'
alias claude='clear && claude'

# Functions ----------------------------------------------------------------------------------

# Tmux: attach to last session, any session, or create 'main'
tm() {
    [[ -n "$TMUX" ]] && return
    local last
    last=$(cat ~/.local/share/tmux/last-session 2>/dev/null)
    if [[ -n "$last" ]] && tmux has-session -t "$last" 2>/dev/null; then
        tmux attach -t "$last"
    elif tmux list-sessions &>/dev/null; then
        tmux attach
    else
        tmux new-session -s main
    fi
}

# Prompt & Plugins ---------------------------------------------------------------------------

eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/prompt.json)"

eval "$(zoxide init zsh)"

source "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

source "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_HIGHLIGHT_STYLES[command]='fg=#E29BD8,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#E29BD8,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#E29BD8,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#BB9AF7,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=#BB9AF7,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#BB9AF7'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#BB9AF7'

# Bat
export BAT_THEME="base16"
export MANPAGER="sh -c 'col -bx | bat -p -lman'"

# Fzf
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND="find -L"
export FZF_DEFAULT_OPTS="
  --color=fg:#888888,fg+:#E29BD8,bg+:#101017,hl:#BB9AF7,hl+:#E29BD8
  --color=info:#555555,prompt:#E29BD8,pointer:#E29BD8,marker:#BB9AF7,border:#252525
  --color=header:#555555,spinner:#BB9AF7
"

# Completions ---------------------------------------------------------------------------------

fpath=($HOME/.docker/completions $fpath)

autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' list-colors "$LS_COLORS" ma=0\;35
zstyle ':completion:*' squeeze-slashes false

# Shell Options ------------------------------------------------------------------------------

setopt append_history inc_append_history share_history hist_ignore_dups hist_ignore_space
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

# Per-pane tmux history
if [[ -n $TMUX_PANE ]]; then
    HISTDIR="$HOME/.zsh_tmux_hist"
    mkdir -p "$HISTDIR"
    HISTFILE="$HISTDIR/.zsh_history_${TMUX_PANE:1}"
    [[ ! -f $HISTFILE ]] && cp "$HOME/.zsh_history" "$HISTFILE" 2>/dev/null
fi

# Auto-attach to tmux in any graphical terminal session
if [[ -z "$TMUX" && (-n "$WAYLAND_DISPLAY" || -n "$DISPLAY") ]]; then
    tm
fi
