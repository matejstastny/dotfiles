#!/usr/bin/env bash
set -e

echo "==> Removing VS Code package..."
sudo dnf remove -y code

echo "==> Removing VS Code config..."
rm -rf ~/.config/Code

echo "==> Removing VS Code extensions and CLI cache..."
rm -rf ~/.vscode

echo "==> Done. VSCodium is untouched."
