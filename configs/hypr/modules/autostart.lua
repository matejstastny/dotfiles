hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm finalize")

    ---------------------------------
    -- SHELL
    ---------------------------------

    hl.exec_cmd("QT_QPA_PLATFORMTHEME=gtk3 qs")                 -- dekstop shell
    hl.exec_cmd("hypridle")                                     -- sleep
    hl.exec_cmd(DOTS .. "/scripts/lock.sh")                     -- lock screen
    hl.exec_cmd("awww-daemon")                                  -- wallpaper daemon
    hl.exec_cmd(DOTS .. "/scripts/wallpaper-restore.sh")        -- get last wallpaper
    hl.exec_cmd(DOTS .. "/scripts/cursor-restore.sh")           -- get last cursor theme
    hl.exec_cmd("wl-paste --type text  --watch cliphist store") -- clipboard
    hl.exec_cmd("wl-paste --type image --watch cliphist store") -- clipboard img
    hl.exec_cmd("/usr/libexec/hyprpolkitagent")                 -- auth agent
    hl.exec_cmd("xhost +si:localuser:root")                     -- root gui perms

    ---------------------------------
    -- GNOME
    ---------------------------------

    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-mauve-standard+default'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Atkinson Hyperlegible Next 8'")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,pkcs11,ssh")

    -- autostart apps
    hl.exec_cmd(DOTS .. "/scripts/session.sh")
end)
