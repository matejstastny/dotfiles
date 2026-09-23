setopt autocd
setopt auto_param_slash
setopt no_case_glob no_case_match
setopt globdots
setopt extended_glob
setopt interactive_comments
setopt long_list_jobs
unsetopt prompt_sp
unsetopt beep

bindkey -e
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[[3~" delete-char
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

# ctrl-z toggles back into the last suspended job
_fg_toggle() {
	if [[ -n $(jobs) ]]; then
		BUFFER="fg"
		zle accept-line
	fi
}
zle -N _fg_toggle
bindkey "^Z" _fg_toggle

stty stop undef
