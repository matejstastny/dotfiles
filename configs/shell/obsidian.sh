#!/bin/zsh

export NOTES_DIR="$HOME/notes"

note() {
	if [ $# -eq 0 ]; then
		builtin cd "$NOTES_DIR" && "$EDITOR" .
		return
	fi
	local f="$NOTES_DIR/$*"
	[[ "$f" == *.md ]] || f="$f.md"
	mkdir -p "$(dirname "$f")"
	"$EDITOR" "$f"
}

today() {
	local dir="$NOTES_DIR/daily" f
	mkdir -p "$dir"
	f="$dir/$(date +%Y-%m-%d).md"
	[ -f "$f" ] || printf '# %s\n\n' "$(date '+%A, %B %d %Y')" >"$f"
	"$EDITOR" "$f"
}

nn() {
	local f
	f=$( (builtin cd "$NOTES_DIR" && rg --files -g '*.md') |
		fzf --prompt '✦ notes ✦ ' \
			--preview "bat --style=numbers --color=always '$NOTES_DIR'/{}")
	[ -n "$f" ] && "$EDITOR" "$NOTES_DIR/$f"
}

ns() {
	local sel file line
	sel=$( (builtin cd "$NOTES_DIR" && rg --line-number --no-heading --color=always -g '*.md' "${*:-.}") |
		fzf --ansi --delimiter : \
			--prompt '✦ search ✦ ' \
			--preview "bat --style=numbers --color=always --highlight-line {2} '$NOTES_DIR'/{1}")
	[ -z "$sel" ] && return
	file=${sel%%:*}
	line=${${sel#*:}%%:*}
	"$EDITOR" "+$line" "$NOTES_DIR/$file"
}

# quick-capture a timestamped line into the inbox (no args → edit inbox)
qn() {
	local inbox="$NOTES_DIR/inbox.md"
	mkdir -p "$NOTES_DIR"
	[ -f "$inbox" ] || printf '# Inbox\n\n' >"$inbox"
	if [ $# -eq 0 ]; then
		"$EDITOR" "$inbox"
		return
	fi
	printf -- '- %s %s\n' "$(date '+%Y-%m-%d %H:%M')" "$*" >>"$inbox"
	echo "✦ captured → inbox.md"
}

# append a todo (matches rofi/todo.sh format; no args → edit list)
todo() {
	local file="$NOTES_DIR/todo/personal.md" tmp
	mkdir -p "$(dirname "$file")"
	[ -f "$file" ] || printf '# Personal\n\n' >"$file"
	if [ $# -eq 0 ]; then
		"$EDITOR" "$file"
		return
	fi
	tmp=$(mktemp)
	{
		head -1 "$file"
		printf -- '- [ ] %s %s\n' "$(date +%Y-%m-%d)" "$*"
		tail -n +2 "$file"
	} >"$tmp"
	mv "$tmp" "$file"
	echo "✦ todo added"
}
