_load() {
	local f
	for f in "$@"; do
		[[ -r $f ]] && { source "$f"; return 0 }
	done
	return 1
}

# bat
export BAT_THEME="base16"
export MANPAGER="sh -c 'col -bx | bat -p -lman'"

# fzf
if (( $+commands[fzf] )); then
	source <(fzf --zsh) 2>/dev/null
	export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	export FZF_CTRL_R_OPTS="--style minimal --info inline --no-sort --no-preview"
	export FZF_DEFAULT_OPTS="
	  --height 40% --layout reverse --border none
	  --color=fg:${MOON_DIM},fg+:#f0f0ff,bg+:-1,hl:${MOON_ACCENT},hl+:${MOON_ALT}
	  --color=info:${MOON_DIM},prompt:${MOON_ACCENT},pointer:${MOON_ACCENT}
	  --color=marker:${MOON_ALT},spinner:${MOON_ACCENT},header:${MOON_DIM}
	"
fi

# syntax highlighting
if _load /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
         /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; then
	ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
	typeset -gA ZSH_HIGHLIGHT_STYLES

	# plain words, and the base every unset region falls back to
	ZSH_HIGHLIGHT_STYLES[default]="fg=${MOON_TEXT}"
	ZSH_HIGHLIGHT_STYLES[arg0]="fg=${MOON_TEXT}"
	ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=${MOON_DANGER},bold,underline"
	ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=${MOON_TEXT},bold"

	# what runs: the host hue, with lookalikes split off onto the lighter tint
	ZSH_HIGHLIGHT_STYLES[command]="fg=${MOON_ACCENT},bold"
	ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=${MOON_ACCENT},bold"
	ZSH_HIGHLIGHT_STYLES[builtin]="fg=${MOON_BRIGHT},bold"
	ZSH_HIGHLIGHT_STYLES[function]="fg=${MOON_BRIGHT},bold"
	ZSH_HIGHLIGHT_STYLES[alias]="fg=${MOON_BRIGHT},bold"
	ZSH_HIGHLIGHT_STYLES[suffix-alias]="fg=${MOON_BRIGHT},underline"
	ZSH_HIGHLIGHT_STYLES[precommand]="fg=${MOON_ACCENT},bold,underline"

	# paths
	ZSH_HIGHLIGHT_STYLES[path]="fg=${MOON_ALT},underline"
	ZSH_HIGHLIGHT_STYLES[path_prefix]="fg=${MOON_ALT},underline"
	ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=${MOON_ALT}"
	ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]="fg=${MOON_ALT}"
	ZSH_HIGHLIGHT_STYLES[autodirectory]="fg=${MOON_ALT},underline"

	# flags
	ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=${MOON_DIM}"
	ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=${MOON_DIM}"

	# quoting and expansion
	ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=${MOON_STRING}"
	ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=${MOON_STRING}"
	ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=${MOON_STRING}"
	ZSH_HIGHLIGHT_STYLES[rc-quote]="fg=${MOON_STRING},bold"
	ZSH_HIGHLIGHT_STYLES[globbing]="fg=${MOON_STRING}"
	ZSH_HIGHLIGHT_STYLES[history-expansion]="fg=${MOON_STRING},bold"
	ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]="fg=${MOON_BRIGHT}"
	ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]="fg=${MOON_BRIGHT}"
	ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]="fg=${MOON_BRIGHT}"
	ZSH_HIGHLIGHT_STYLES[back-quoted-argument]="fg=${MOON_DIM}"
	ZSH_HIGHLIGHT_STYLES[command-substitution]="fg=${MOON_TEXT}"
	ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]="fg=${MOON_ALT}"
	ZSH_HIGHLIGHT_STYLES[process-substitution]="fg=${MOON_TEXT}"
	ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]="fg=${MOON_ALT}"
	ZSH_HIGHLIGHT_STYLES[assign]="fg=${MOON_BRIGHT}"

	# plumbing. commandseparator covers && || | ; & and defaults to none
	ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=${MOON_DIM},bold"
	ZSH_HIGHLIGHT_STYLES[redirection]="fg=${MOON_ALT},bold"
	ZSH_HIGHLIGHT_STYLES[named-fd]="fg=${MOON_DIM}"
	ZSH_HIGHLIGHT_STYLES[numeric-fd]="fg=${MOON_DIM}"
	ZSH_HIGHLIGHT_STYLES[comment]="fg=${MOON_MUTED},italic"

	ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=${MOON_ACCENT}"
	ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=${MOON_ALT}"
	ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=${MOON_STRING}"
	ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=${MOON_DANGER},bold"
	ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="standout"
else
	echo "error: zsh-syntax-highlighting failed to source"
fi

# autosuggestions
if _load /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
         /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; then
	ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${MOON_DIM},italic"
	ZSH_AUTOSUGGEST_STRATEGY=(history completion)
	ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
else
	echo "error: zsh-autosuggestions failed to source"
fi

unfunction _load

(( $+commands[starship] )) && eval "$(starship init zsh)"

# zoxide wants to be last
(( $+commands[zoxide] )) && { eval "$(zoxide init zsh)"; alias cd='z' }
