#!/usr/bin/env bash
set -euo pipefail

echo "✦ Installing VSCode..."
sudo dnf install -y code

echo "✦ Migrating extensions from VSCodium..."
codium --list-extensions | while read -r ext; do
    code --install-extension "$ext" || true
done

echo "✦ Applying custom CSS..."
"$(dirname "$0")/../bin/patch-vscode"

echo "✦ Done."
