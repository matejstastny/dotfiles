if [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    $HOME/dotfiles/bin/hyprland-session
fi
