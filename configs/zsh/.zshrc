# Defaults
export EDITOR="nvim"
export BROWSER="helium"
export DOTFILES_DIR="$HOME/dotfiles"

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# SDKS
export GOPATH="$HOME/go"
export PROTO_HOME="$HOME/.proto"
export BUN_INSTALL="$HOME/.bun"

# Path
typeset -U path
path=(
	"$HOME/dotfiles/bin"
	"$GOPATH/bin"
	"$BUN_INSTALL/bin"
	"$PROTO_HOME/shims"
	"$PROTO_HOME/bin"
	"$HOME/.local/bin"
	$path
)

# Aliases ------------------------------------------------------------------------------------

alias dots='cd ~/dotfiles'
alias s='ls ~/dotfiles/bin'

alias lg='lazygit'
alias gs='git status -sb'
alias ga='git add'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gb='gh browse'

alias ani='ani-cli'
alias mem='sudo ps_mem'
alias copy='wl-copy'
alias paste='wl-paste'
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

alias ip='echo "not configured"'

alias q='tmux detach'
alias qa='tmux kill-server'
alias tl='tmux display-message -p "#{window_layout}"'

alias dockerc='docker system prune --all --volumes'

alias n='clear && fastfetch'

alias cc='clear && claude --dangerously-skip-permissions'
alias ccc='clear && claude --dangerously-skip-permissions --continue'

# Yazi — cd into directory on exit
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Prompt & Plugins ---------------------------------------------------------------------------

# Oh My Posh
eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/prompt.json)"

# Zoxide
eval "$(zoxide init zsh)"

# Zsh autosuggestions
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#9b8ab0,italic"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Zsh syntax highlighting
source ~/dotfiles/zsh-highlighting.sh || true

# Bat
export BAT_THEME="base16"
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# Fzf
source <(fzf --zsh)
export FZF_CTRL_R_OPTS="--style minimal --color 16 --info inline --no-sort --no-preview"
export FZF_DEFAULT_COMMAND="find -L"
export FZF_DEFAULT_OPTS="
  --color=fg:#9b8ab0,fg+:#e0d4f0,bg+:#1c1528,hl:#7c5cbf,hl+:#c47a9b
  --color=info:#9b8ab0,prompt:#7c5cbf,pointer:#7c5cbf,marker:#c47a9b,border:#3d2f52
  --color=header:#9b8ab0,spinner:#7c5cbf
"

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

if [[ "$TERM" == "xterm-kitty" ]]; then
	tm
fi

# pnpm
export PNPM_HOME="/home/elara/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME/bin:"*) ;;
*) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# Vite+ bin (https://viteplus.dev)
. "$HOME/.vite-plus/env"
