# Matej Stastny | https://github.com/matejstastny/dotfiles

# Defaults ----------------------------------------------------------------------------------

export EDITOR="nvim"
export BROWSER="firefox"
export DOTFILES_DIR="$HOME/dotfiles"

# Locale ------------------------------------------------------------------------------------

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# XDG Base Directories ----------------------------------------------------------------------

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# fzf defaults ------------------------------------------------------------------------------

export FZF_DEFAULT_OPTS="--style minimal --color 16 --layout=reverse --height 30% --preview='bat -p --color=always {}'"
export FZF_CTRL_R_OPTS="--style minimal --color 16 --info inline --no-sort --no-preview"

# SDKs --------------------------------------------------------------------------------------

export GOPATH="$HOME/go"
export PROTO_HOME="$HOME/.proto"
export BUN_INSTALL="$HOME/.bun"

# Linux (Fedora) ---------------------------------------------------------------------------

export APP_DATA="$XDG_DATA_HOME"

# PATH setup --------------------------------------------------------------------------------

typeset -U path

path=(
	"$HOME/dotfiles/bin"
	"$HOME/bin/bin"
	"$GOPATH/bin"
	$path
)
