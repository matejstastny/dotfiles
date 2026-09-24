#!/usr/bin/env python3
#@ emit vscode project MRU + workspace state as JSON, for the quickshell code picker
import json
import os

storage = os.path.expanduser("~/.config/Code/User/globalStorage/storage.json")
history_file = os.path.expanduser("~/.local/share/vscode-projects")
home = os.environ["HOME"]

os.makedirs(os.path.dirname(history_file), exist_ok=True)
open(history_file, "a").close()

seen = set()
paths = []


def add(path):
    if not path or path in seen:
        return
    seen.add(path)
    paths.append(path)


with open(history_file) as f:
    for line in f:
        add(line.strip())

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
    with open(history_file) as f:
        existing = {l.strip() for l in f}
    new_entries = [p for p in vscode_paths if p not in existing]
    if new_entries:
        with open(history_file, "a") as f:
            for p in new_entries:
                f.write(p + "\n")


def has_devcontainer(path):
    return os.path.isdir(os.path.join(path, ".devcontainer")) or os.path.isfile(
        os.path.join(path, ".devcontainer.json")
    )


print(
    json.dumps(
        [
            {
                "path": p,
                "display": p.replace(home, "~", 1),
                "devcontainer": has_devcontainer(p),
            }
            for p in paths
        ]
    )
)
