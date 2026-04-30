# Matej Stastny | https://github.com/matejstastny/dotfiles

# Aliases ------------------------------------------------------------------------------------

alias ..='cd ..'
alias ...='cd ../..'
alias dots='cd ~/dotfiles'
alias scr='ls ~/bin/bin'

alias lg='lazygit'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'

alias copy='pbcopy'
alias paste='pbpaste'
alias path='echo $PATH | tr ":" "\n"'
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'
alias nocolor='gsed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g"'

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

alias n='clear && fastfetch'

alias cc='clear && claude --dangerously-skip-permissions'
alias ccc='clear && claude --dangerously-skip-permissions --continue'
alias claude='clear && claude'

alias nv='nvim'
alias ssh='$HOME/bin/bin/ssh'

# Prompt & Plugins ---------------------------------------------------------------------------

# Oh My Posh
eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/prompt.json)"

# Zoxide
eval "$(zoxide init zsh)"

# Zsh autosuggestions
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Zsh syntax highlighting
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_HIGHLIGHT_STYLES[command]='fg=#E29BD8,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#E29BD8,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#E29BD8,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#BB9AF7,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=#BB9AF7,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#BB9AF7'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#BB9AF7'

# Ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/.ripgreprc"

# Bat
export BAT_THEME="base16"
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# Fzf
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND="find -L"
export FZF_DEFAULT_OPTS="
  --color=fg:#888888,fg+:#E29BD8,bg+:#101017,hl:#BB9AF7,hl+:#E29BD8
  --color=info:#555555,prompt:#E29BD8,pointer:#E29BD8,marker:#BB9AF7,border:#252525
  --color=header:#555555,spinner:#BB9AF7
"

# Jenv
if command -v jenv >/dev/null 2>&1; then
	export PATH="$HOME/.jenv/bin:$PATH"
	eval "$(jenv init -)"
fi

# Completions ---------------------------------------------------------------------------------

fpath=($HOME/.docker/completions $fpath)
[ -s "${BUN_INSTALL:-$HOME/.bun}/_bun" ] && source "${BUN_INSTALL:-$HOME/.bun}/_bun"

autoload -Uz compinit
compinit

# Completion settings
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

# Tmux separate history
if [[ -n $TMUX_PANE ]]; then
	HISTDIR="$HOME/.zsh_tmux_hist"
	mkdir -p "$HISTDIR"
	HISTFILE="$HISTDIR/.zsh_history_${TMUX_PANE:1}"
	if [[ ! -f $HISTFILE ]]; then
		cp "$HOME/.zsh_history" "$HISTFILE" 2>/dev/null
	fi
fi

# Attach to tmux session
if [[ $TERM == "xterm-ghostty" ]]; then
	tm
fi
