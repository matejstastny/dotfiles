-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprlock")
    hl.exec_cmd("swww-daemon")
    hl.exec_cmd(
        "swww img --wait-for-daemon ~/dotfiles/assets/wallpapers/wallpaper.png --transition-type fade --transition-duration 1.5")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,pkcs11,ssh")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-mauve-standard+default'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Atkinson Hyperlegible Next 10'")
end)

-- Monitors
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x400", scale = 1.60 })
hl.monitor({ output = "DP-1", mode = "preferred", position = "1600x0", scale = 1.5 })

-- Auto-fix Apple DCP valid_mode:0 race (DP-1 appears black on connect)
hl.on("monitor.added", function(monitor)
    if monitor.name ~= "DP-1" then return end
    hl.exec_cmd("sh -c 'sleep 2 && ~/dotfiles/bin/fix-dp1'")
end)

-- Env
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("GTK_THEME", "catppuccin-mocha-mauve-standard+default")
hl.env("GDK_SCALE", 1);
hl.env("GDK_DPI_SCALE", 1);

-- Look & feel
hl.config({
    general = {
        gaps_in          = 4,
        gaps_out         = 8,
        border_size      = 2,
        col              = {
            active_border   = "rgba(7c5cbfff)",
            inactive_border = "rgba(1c1528aa)",
        },
        layout           = "dwindle",
        resize_on_border = true,
        allow_tearing    = true,
    },
    decoration = {
        rounding = 8,
        shadow   = { enabled = false },
        blur     = { enabled = true, size = 6, passes = 2, new_optimizations = true },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        disable_hyprland_logo   = true,
        force_default_wallpaper = 0,
    },
    render = {
        direct_scanout = true,
    },
})

-- Minimal animations (fast, not distracting)
hl.curve("snappy", { type = "bezier", points = { { 0.2, 1 }, { 0.2, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "snappy" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "snappy", style = "slide" })

-- Input
hl.config({
    input = {
        kb_layout     = "us",
        kb_options    = "ctrl:swap_lwin_lctl",
        follow_mouse  = 1,
        touchpad      = {
            natural_scroll       = true,
            tap_to_click         = true,
            drag_lock            = true,
            clickfinger_behavior = true,
            disable_while_typing = false,
        },
        -- keyboard
        repeat_delay  = 190,
        repeat_rate   = 30,
        sensitivity   = 0.1,
        accel_profile = "flat",
    },
})

-- This is for my windows keyboard to feel as a mac one
hl.device({ name = "keychron-keychron-k1-se", kb_options = "ctrl:swap_lalt_lctl_lwin" })
hl.device({ name = "keychron-keychron-k1-se-2", kb_options = "ctrl:swap_lalt_lctl_lwin" })

-- 3-finger swipe to switch workspaces (like yabai/macOS)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

local mod = "ALT"

-- Apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("nautilus"))

-- Window: close like yabai mod+w
hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }))
-- Center a floating window
hl.bind(mod .. " + C", hl.dsp.window.center())

-- Move windows in tiling
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- Workspaces 1-9
for i = 1, 9 do
    local key = tostring(i)
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces with mod + scroll
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move active workspace to the other monitor
hl.bind(mod .. " + tab", function()
    local mon = hl.get_active_monitor()
    if not mon then return end
    local target = mon.name == "eDP-1" and "DP-1" or "eDP-1"
    local ws = hl.get_active_workspace()
    if not ws then return end
    hl.dispatch(hl.dsp.workspace.move({ workspace = ws.id, monitor = target }))
end)

-- Move/resize with mod + drag (like yabai mod+drag)
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media & brightness keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Fix black external display (Apple DCP race workaround)
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/fix-dp1"))

-- Lock screen
hl.bind(mod .. " + CTRL + L", hl.dsp.exec_cmd("hyprlock"))

-- Power menu
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/powermenu"))

-- Screenshot (macOS-style: physical CMD = CTRL due to swap_lwin_lctl)
hl.bind("CTRL + SHIFT + 4", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/screenshot"))
hl.bind("CTRL + SHIFT + 3", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/screenshot-full"))

-- Clipboard history picker
hl.bind(mod .. " + V", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/clip"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/emoji"))

-- VSCode recent projects picker
hl.bind(mod .. " + P", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/vscode-projects"))

-- Exit (mod+shift+q to avoid accidents)
hl.bind(mod .. " + SHIFT + Q", hl.dsp.exit())

-- Window rules
hl.on("window.open", function(window)
    if window.class:find("^blueman") then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ exact = true, x = 400, y = 600 }))
        hl.dispatch(hl.dsp.window.center())
    end
    if window.class:find("chrome%-nngceckbapebfimnlniiiahkandclblb") then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ exact = true, x = 400, y = 600 }))
        hl.dispatch(hl.dsp.window.center())
    end
end)
hl.window_rule({
    name      = "minecraft-immediate",
    match     = { class = "^Minecraft" },
    immediate = true,
})
hl.window_rule({
    name           = "suppress-maximize",
    match          = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    name     = "fix-xwayland-drags",
    match    = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
