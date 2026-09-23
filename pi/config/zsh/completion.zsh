autoload -Uz compinit

# rebuild the dump at most once a day, the pi's sd card is slow
_zcompdump="$XDG_CACHE_HOME/zcompdump"
mkdir -p "${_zcompdump:h}"
if [[ -n ${_zcompdump}(#qN.mh+24) ]]; then
	compinit -d "$_zcompdump"
else
	compinit -C -d "$_zcompdump"
fi
unset _zcompdump

zmodload -i zsh/complist

zstyle ':completion:*' menu select
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes false
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zcompcache"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" "ma=48;5;239"
zstyle ':completion:*:descriptions' format "%F{${MOON_DIM}}%d%f"
zstyle ':completion:*:messages' format "%F{${MOON_DIM}}%d%f"
zstyle ':completion:*:warnings' format "%F{${MOON_ALT}}no match%f"

bindkey -M menuselect '^[[Z' reverse-menu-complete
