local mod = "ALT"

-- apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + H",         hl.dsp.exec_cmd("helium"))
hl.bind(mod .. " + SHIFT + H", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/helium-stars"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("vesktop"))

-- rofi
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("/home/elara/dotfiles/rofi/wifi.sh"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("/home/elara/dotfiles/rofi/calc.sh"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("/home/elara/dotfiles/rofi/clip.sh"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("/home/elara/dotfiles/rofi/emoji.sh"))
hl.bind(mod .. " + P", hl.dsp.exec_cmd("/home/elara/dotfiles/rofi/vscode.sh"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("/home/elara/dotfiles/rofi/bluetooth.sh"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("/home/elara/dotfiles/rofi/todo.sh personal"))
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("/home/elara/dotfiles/rofi/powermenu.sh"))
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("/home/elara/dotfiles/rofi/todo.sh stars"))

-- utils
hl.bind(mod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/fix-dp1"))

-- screenshot
hl.bind("CTRL + SHIFT + 4", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/screenshot"))
hl.bind("CTRL + SHIFT + 3", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/screenshot-full"))

-- session
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/session"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("/home/elara/dotfiles/bin/close-session"))

-- window managment
hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + C", hl.dsp.window.center())

hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- workspaces
for i = 1, 9 do
    local key = tostring(i)
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- switch monitors
hl.bind(mod .. " + tab", function()
    local mon = hl.get_active_monitor()
    if not mon then return end
    local target = mon.name == "eDP-1" and "DP-1" or "eDP-1"
    local ws = hl.get_active_workspace()
    if not ws then return end
    hl.dispatch(hl.dsp.workspace.move({ workspace = ws.id, monitor = target }))
end)

-- mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- fn key functions
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"),
    { locked = true, repeating = true })
