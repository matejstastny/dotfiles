if [[ -z $DISPLAY && -z $WAYLAND_DISPLAY && $XDG_VTNR -eq 1 ]]; then
    $HOME/dotfiles/bin/hyprland-session
fi
