# --------------------------------------------------------------------------------------------
# .zshrc - my zsh configuration file
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-03-02 (YYYY-MM-DD)
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------

# Aliases ------------------------------------------------------------------------------------

alias ..='cd ..'
alias ...='cd ../..'
alias dots='cd ~/dotfiles'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias lg='lazygit'
alias copy='pbcopy'
alias paste='pbpaste'
alias ppath='echo $PATH | tr ":" "\n"'
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'
alias zrc='${EDITOR} ~/.zshrc'
alias zpr='${EDITOR} ~/.zprofile'

alias d='trash'
alias c='clear'
alias info='scc'
alias aria='aria2c'

alias cd='z'
alias ls='echo && eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
alias lsa='echo && eza --color=always --long --git --icons=always'
alias lsaa='echo && eza --color=always --long --git --icons=always -a'
alias lst='echo && eza --color=always --tree --git --no-filesize --icons=always --no-time --no-user --no-permissions'

alias ip="ifconfig | grep 'inet ' | awk '/inet / {print \$2}' | grep -Ev '^(127\.|::)'"
alias sign='sudo xattr -rd com.apple.quarantine'

alias q='tmux detach'
alias qa='tmux kill-server'
alias tl='tmux display-message -p "#{window_layout}"'

alias vc='veracrypt -t'

alias dockerc='docker system prune --all --volumes'

alias n='clear && fastfetch -c $HOME/.config/fastfetch/themes/cat.jsonc'
alias nm='clear && fastfetch -c $HOME/.config/fastfetch/themes/fastcat.jsonc'
alias nd='clear && fastfetch -c $HOME/.config/fastfetch/themes/detailed.jsonc'
alias nj='clear && fastfetch -c $HOME/.config/fastfetch/themes/jellyfish.jsonc'

alias cc='clear && claude'
alias claude='clear && claude'

alias y='yazi'
alias bonsai='cbonsai -l -t 0.02'
alias pipes='pipes-rs'

# Prompt & Plugins ---------------------------------------------------------------------------

# Starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

# Zoxide
eval "$(zoxide init zsh)"

# Zsh autosuggestions
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Zsh syntax highlighting
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_HIGHLIGHT_STYLES[command]='fg=#7E9CD8,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#957FB8,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#7E9CD8,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#7FB4CA,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#C34043'
ZSH_HIGHLIGHT_STYLES[path]='fg=#98BB6C,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#98BB6C'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#98BB6C'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#E6C384'

# Bat
export BAT_THEME="kanagawa"
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# Fzf
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND="find -L"
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#2A2A37,bg:-1,fg:#DCD7BA,fg+:#DCD7BA \
  --color=hl:#7E9CD8,hl+:#7E9CD8,info:#E6C384,marker:#98BB6C \
  --color=prompt:#957FB8,spinner:#957FB8,pointer:#957FB8,border:#727169 \
  --color=header:#7E9CD8,gutter:-1,separator:#727169"

# Jenv
if command -v jenv >/dev/null 2>&1; then
	export PATH="$HOME/.jenv/bin:$PATH"
	eval "$(jenv init -)"
fi

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

if [[ -n $TMUX_PANE ]]; then
	HISTDIR="$HOME/.zsh_tmux_hist"
	mkdir -p "$HISTDIR"
	HISTFILE="$HISTDIR/.zsh_history_${TMUX_PANE:1}"
	if [[ ! -f $HISTFILE ]]; then
		cp "$HOME/.zsh_history" "$HISTFILE" 2>/dev/null
	fi
fi
