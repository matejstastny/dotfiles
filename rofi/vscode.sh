#!/usr/bin/env bash
history_file="$HOME/.local/share/vscode-projects"
mkdir -p "$(dirname "$history_file")"
touch "$history_file"

get_list() {
	python3 - <<'EOF'
import json, os

storage = os.path.expanduser("~/.config/VSCodium/User/globalStorage/storage.json")
history_file = os.path.expanduser("~/.local/share/vscode-projects")
home = os.environ["HOME"]

seen = set()
paths = []

def add(path):
    if not path or path in seen:
        return
    seen.add(path)
    paths.append(path)

try:
    with open(history_file) as f:
        for line in f:
            add(line.strip())
except FileNotFoundError:
    pass

vscode_paths = []
try:
    data = json.load(open(storage))
    for entry in data.get("backupWorkspaces", {}).get("folders", []):
        uri = entry.get("folderUri", "")
        if uri.startswith("file://"):
            vscode_paths.append(uri[7:])
    ws = data.get("windowsState", {})
    for w in [ws.get("lastActiveWindow", {})] + ws.get("openedWindows", []):
        uri = w.get("folder", "")
        if uri and uri.startswith("file://"):
            vscode_paths.append(uri[7:])
except Exception:
    pass

for p in vscode_paths:
    add(p)

if vscode_paths:
    existing = set()
    try:
        with open(history_file) as f:
            existing = {l.strip() for l in f}
    except FileNotFoundError:
        pass
    new_entries = [p for p in vscode_paths if p not in existing]
    if new_entries:
        with open(history_file, "a") as f:
            for p in new_entries:
                f.write(p + "\n")

def has_devcontainer(path):
    return (os.path.isdir(os.path.join(path, ".devcontainer")) or
            os.path.isfile(os.path.join(path, ".devcontainer.json")))

for p in paths:
    display = p.replace(home, "~", 1)
    prefix = "[dc] " if has_devcontainer(p) else ""
    print(f"{prefix}{display}")
EOF
}

while true; do
	selected=$(get_list | rofi -dmenu \
		-p "✦ code ✦" \
		-kb-custom-1 "Alt+BackSpace" \
		-kb-custom-2 "Alt+d" \
		-mesg "Alt+Backspace: remove  |  Alt+D: open in devcontainer")
	exit_code=$?

	[ $exit_code -eq 1 ] && exit 0
	[ -z "$selected" ] && exit 0

	# Strip [dc] prefix to get the bare path
	path_part="$selected"
	[[ "$path_part" == "[dc] "* ]] && path_part="${path_part#\[dc\] }"

	abs="${path_part/#\~/$HOME}"

	if [ $exit_code -eq 10 ]; then
		tmp=$(mktemp)
		grep -Fxv "$abs" "$history_file" >"$tmp"
		mv "$tmp" "$history_file"
		continue
	fi

	tmp=$(mktemp)
	echo "$abs" >"$tmp"
	grep -Fxv "$abs" "$history_file" | head -49 >>"$tmp"
	mv "$tmp" "$history_file"

	if [ $exit_code -eq 11 ]; then
		kitty devcon "$abs" &
	else
		codium "$abs"
	fi
	exit 0
done
