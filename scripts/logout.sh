#!/usr/bin/env bash
#@ close apps and cleanly exit hyprland, dropping back to the tty login

"$(dirname "$0")/session.sh" close
uwsm stop
