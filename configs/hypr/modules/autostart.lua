hl.on("hyprland.start", function()
    -- plugins
    hl.exec_cmd("hyprpm reload")

    ---------------------------------
    -- SHELL
    ---------------------------------

    hl.exec_cmd("noctalia --daemon")
    -- hl.exec_cmd("hypridle")
    -- hl.exec_cmd("hyprlock")
    -- hl.exec_cmd("swww-daemon")
    -- hl.exec_cmd(DOTS .. "/bin/wallpaper-restore")
    -- hl.exec_cmd("swayosd-server")
    -- hl.exec_cmd("waybar")
    -- hl.exec_cmd("swaync")
    -- hl.exec_cmd("nm-applet --indicator")
    -- hl.exec_cmd("blueman-applet")
    -- hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    -- hl.exec_cmd("wl-paste --type image --watch cliphist store")

    ---------------------------------
    -- GNOME
    ---------------------------------

    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-mauve-standard+default'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Atkinson Hyperlegible Next 10'")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,pkcs11,ssh")

    -- autostart apps
    hl.exec_cmd(DOTS .. "/bin/session")
end)
