# defaults
export WHICH_CODE="codium"
export EDITOR="nvim"
export BROWSER="helium"
export DOTFILES_DIR="$HOME/dotfiles"

# locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# sdks
export GOPATH="$HOME/go"
export PROTO_HOME="$HOME/.proto"
export BUN_INSTALL="$HOME/.bun"

# path
typeset -U path
path=(
	"$HOME/dotfiles/bin"
	"$GOPATH/bin"
	"$BUN_INSTALL/bin"
	"$PROTO_HOME/shims"
	"$PROTO_HOME/bin"
	"$HOME/.local/bin"
	"$HOME/.cargo/bin"
	"$HOME/.devcontainers/bin"
	"$HOME/.pixi/bin"
	$path
)

# Aliases ------------------------------------------------------------------------------------

alias dots='cd ~/dotfiles'
alias s='scripts'

alias tfd='npx -y trickfire-docs@latest dev'

alias sr='source ~/.zshrc && echo "shell reloaded"'

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

alias lip="hostname -I | cut -d ' ' -f 1"

alias q='tmux detach'
alias qa='tmux kill-server'
alias tl='tmux display-message -p "#{window_layout}"'

alias dockerc='docker system prune --all --volumes'

alias n='clear && fastfetch'

alias cc='clear && claude --dangerously-skip-permissions'
alias ccc='clear && claude --dangerously-skip-permissions --continue'

# plugins ------------------------------------------------------------------------------------

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# plugins
source $HOME/.config/shell/zsh-highlighting.sh || echo "error: zsh-syntax-highliting failed to source"
source $HOME/.config/shell/obsidian.sh || echo "error: obsidian failed to source"
source $HOME/.config/shell/yazi.sh || echo "error: yazi failed to source"

# zsh-autosuggestions
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#9b8ab0,italic"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# bat
export BAT_THEME="base16"
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# fzf
source <(fzf --zsh)
export FZF_CTRL_R_OPTS="--style minimal --color 16 --info inline --no-sort --no-preview"
export FZF_DEFAULT_COMMAND="find -L"
export FZF_DEFAULT_OPTS="
  --color=fg:#9898c0,fg+:#f0f0ff,bg+:#181825,hl:#7878c8,hl+:#c47ab8
  --color=info:#9898c0,prompt:#7878c8,pointer:#7878c8,marker:#c47ab8,border:#3d3d5c
  --color=header:#9898c0,spinner:#7878c8
"

# completions ---------------------------------------------------------------------------------

fpath=($HOME/.docker/completions $fpath)
[ -s "${BUN_INSTALL:-$HOME/.bun}/_bun" ] && source "${BUN_INSTALL:-$HOME/.bun}/_bun"

autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' list-colors "$LS_COLORS" ma=0\;35
zstyle ':completion:*' squeeze-slashes false

_rmt() {
	local -a hosts
	hosts=(${(f)"$(rmt --complete 2>/dev/null)"})
	_describe 'host' hosts
}
compdef _rmt rmt

# shell options ------------------------------------------------------------------------------

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

# history ------------------------------------------------------------------------------------

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

# other --------------------------------------------------------------------------------------

# pnpm
export PNPM_HOME="/home/elara/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME/bin:"*) ;;
*) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# vite plus
. "$HOME/.vite-plus/env"

# LEAVE AT THE BOTTOM
if [[ "$TERM" == "xterm-kitty" ]]; then
	tm
fi
