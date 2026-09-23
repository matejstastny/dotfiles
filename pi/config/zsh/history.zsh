HISTSIZE=200000
SAVEHIST=200000
HISTFILE="$XDG_CACHE_HOME/zsh_history"
mkdir -p "${HISTFILE:h}"

setopt append_history inc_append_history share_history
setopt hist_ignore_dups hist_ignore_all_dups hist_ignore_space
setopt hist_reduce_blanks hist_verify
