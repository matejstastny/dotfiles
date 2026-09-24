#!/usr/bin/env bash
#@ lock the session via the quickshell lockscreen

pgrep -f "qs -p $HOME/.config/quickshell-lock" >/dev/null || qs -p "$HOME/.config/quickshell-lock" -d
