local mod = "ALT"

-- apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))

-- rofi
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd(DOTS .. "/rofi/wifi.sh"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd(DOTS .. "/rofi/calc.sh"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd(DOTS .. "/rofi/clip.sh"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(DOTS .. "/rofi/emoji.sh"))
hl.bind(mod .. " + P", hl.dsp.exec_cmd(DOTS .. "/rofi/code.sh"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(DOTS .. "/rofi/bluetooth.sh"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd(DOTS .. "/rofi/todo.sh personal"))
hl.bind(mod .. " + O", hl.dsp.exec_cmd(DOTS .. "/rofi/notes.sh"))
hl.bind(mod .. " + I", hl.dsp.exec_cmd(DOTS .. "/rofi/capture.sh"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("qs ipc call panel toggle"))
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd(DOTS .. "/rofi/powermenu.sh"))
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd(DOTS .. "/rofi/todo.sh stars"))

-- utils
hl.bind(mod .. " + G", hl.dsp.exec_cmd(DOTS .. "/bin/git-ui"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd(DOTS .. "/bin/reload-shell"))
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("waypaper"))
hl.bind(mod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))

-- screenshot / record
hl.bind("CTRL + SHIFT + 4", hl.dsp.exec_cmd(DOTS .. "/bin/screenshot"))
hl.bind("CTRL + SHIFT + 3", hl.dsp.exec_cmd(DOTS .. "/bin/screenshot-full"))
hl.bind("CTRL + SHIFT + R", hl.dsp.exec_cmd(DOTS .. "/bin/record"))
hl.bind("CTRL + SHIFT + P", hl.dsp.exec_cmd(DOTS .. "/rofi/screenrecord.sh"))

-- session
hl.bind(mod .. " + SHIFT + O", hl.dsp.exec_cmd(DOTS .. "/bin/session"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd(DOTS .. "/bin/close-session"))

-- window managment
hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + C", hl.dsp.window.center())

hl.bind(mod .. " + SHIFT + left", function() hl.dispatch(hl.plugin.hy3.move_window('left')) end)
hl.bind(mod .. " + SHIFT + right", function() hl.dispatch(hl.plugin.hy3.move_window('right')) end)
hl.bind(mod .. " + SHIFT + up", function() hl.dispatch(hl.plugin.hy3.move_window('up')) end)
hl.bind(mod .. " + SHIFT + down", function() hl.dispatch(hl.plugin.hy3.move_window('down')) end)

-- workspaces
for i = 1, 9 do
    local key = tostring(i)
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- cycle hy3 tabs
hl.bind("CTRL + tab", function() hl.dispatch(hl.plugin.hy3.focus_tab({ direction = 'right', wrap = true })) end)
hl.bind("CTRL + SHIFT + tab", function() hl.dispatch(hl.plugin.hy3.focus_tab({ direction = 'left', wrap = true })) end)

-- switch monitors
hl.bind(mod .. " + tab", function()
    local ws = hl.get_active_workspace()
    local mon = hl.get_active_monitor()
    if not ws or not mon then return end
    local target = mon.name == "eDP-1" and "DP-1" or "eDP-1"
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
