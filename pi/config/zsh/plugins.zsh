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
	ZSH_HIGHLIGHT_STYLES[default]="none"
	ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=${MOON_ALT}"
	ZSH_HIGHLIGHT_STYLES[command]="fg=${MOON_ACCENT}"
	ZSH_HIGHLIGHT_STYLES[builtin]="fg=${MOON_ACCENT}"
	ZSH_HIGHLIGHT_STYLES[function]="fg=${MOON_ACCENT}"
	ZSH_HIGHLIGHT_STYLES[alias]="fg=${MOON_ACCENT}"
	ZSH_HIGHLIGHT_STYLES[precommand]="fg=${MOON_ACCENT},italic"
	ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=${MOON_ALT}"
	ZSH_HIGHLIGHT_STYLES[path]="fg=#dce0f4"
	ZSH_HIGHLIGHT_STYLES[globbing]="fg=${MOON_ALT}"
	ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=${MOON_DIM}"
	ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=${MOON_DIM}"
	ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]="fg=${MOON_ALT}"
	ZSH_HIGHLIGHT_STYLES[comment]="fg=${MOON_DIM},italic"
	ZSH_HIGHLIGHT_STYLES[redirection]="fg=${MOON_ALT}"
	ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=${MOON_ACCENT}"
	ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=${MOON_ALT}"
	ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=${MOON_DIM}"
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
