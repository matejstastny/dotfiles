hl.on("hyprland.start", function()
    -- plugins
    hl.exec_cmd("hyprpm reload")

    ---------------------------------
    -- PORTALS
    ---------------------------------

    hl.exec_cmd("/usr/libexec/xdg-desktop-portal-hyprland")
    hl.exec_cmd("/usr/libexec/xdg-desktop-portal")

    ---------------------------------
    -- SHELL
    ---------------------------------

    -- hl.exec_cmd("noctalia --daemon")                         -- noctalia
    hl.exec_cmd("QT_QPA_PLATFORMTHEME=gtk3 qs")                 -- dekstop shell
    hl.exec_cmd("hypridle")                                     -- sleep
    hl.exec_cmd(DOTS .. "/bin/lock")                            -- lock screen
    hl.exec_cmd("swww-daemon")                                  -- wallpaper daemon
    hl.exec_cmd(DOTS .. "/bin/wallpaper-restore")               -- get last wallpaper
    hl.exec_cmd("nm-applet --indicator")                        -- wifi
    hl.exec_cmd("blueman-applet")                               -- bluetooth
    hl.exec_cmd("wl-paste --type text  --watch cliphist store") -- clipboard
    hl.exec_cmd("wl-paste --type image --watch cliphist store") -- clipboard img

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
