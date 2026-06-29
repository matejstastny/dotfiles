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
end)

-- Monitors
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.60 })
hl.monitor({ output = "DP-1", mode = "preferred", position = "1600x0", scale = 1.5 })

-- Env
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("GDK_SCALE", "2")

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
    },
    decoration = {
        rounding = 8,
        shadow   = { enabled = false },
        blur     = { enabled = false },
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
        },
        -- keyboard
        repeat_delay  = 190,
        repeat_rate   = 30,
        sensitivity   = 0.1,
        accel_profile = "flat",
    },
})

-- 3-finger swipe to switch workspaces (like yabai/macOS)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

local mod = "ALT"

-- Apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("nautilus"))

-- Window: close like yabai mod+w
hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }))
-- Center a floating window
hl.bind(mod .. " + C", hl.dsp.window.center())

-- Focus (vim hjkl + arrow keys)
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))

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

-- Move/resize with mod + drag (like yabai mod+drag)
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media & brightness keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Lock screen
hl.bind(mod .. " + CTRL + L", hl.dsp.exec_cmd("hyprlock"))

-- Screenshot (macOS-style: physical CMD = CTRL due to swap_lwin_lctl)
hl.bind("CTRL + SHIFT + 4", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/screenshot"))
hl.bind("CTRL + SHIFT + 3", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/screenshot-full"))

-- Clipboard history picker
hl.bind(mod .. " + V", hl.dsp.exec_cmd("clip"))

-- Exit (mod+shift+q to avoid accidents)
hl.bind(mod .. " + SHIFT + Q", hl.dsp.exit())

-- Window rules
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
