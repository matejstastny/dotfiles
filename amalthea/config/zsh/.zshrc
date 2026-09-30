# defaults
export EDITOR="nvim"
export DOTFILES_DIR="$HOME/dotfiles/amalthea"

# locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# path
typeset -U path
path=(
	"$HOME/dotfiles/amalthea/bin"
	"$HOME/.local/bin"
	"$HOME/.cargo/bin"
	$path
)

# aliases
alias c='clear'
alias info='scc'
alias dots='cd ~/dotfiles'
alias n='clear && fastfetch'

alias cd='z'
alias ls='echo && eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
alias lsa='echo && eza --color=always --long --git --icons=always'
alias lsaa='echo && eza --color=always --long --git --icons=always -a'
alias lst='echo && eza --color=always --tree --git --no-filesize --icons=always --no-time --no-user --no-permissions'

# plugins
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

source $HOME/.config/shell/zsh-highlighting.sh || echo "error: zsh-syntax-highliting failed to source"
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#9b8ab0,italic"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# bat
export BAT_THEME="base16"
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# shell options
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

# history
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE="$XDG_CACHE_HOME/zsh_history"
