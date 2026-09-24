local mod = "ALT"

-- apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))

-- quickshell menus
hl.bind(mod .. " + Space", hl.dsp.global("quickshell:launcher"))
hl.bind(mod .. " + N", hl.dsp.global("quickshell:wifimenu"))
hl.bind(mod .. " + V", hl.dsp.global("quickshell:clip"))
hl.bind(mod .. " + E", hl.dsp.global("quickshell:emoji"))
hl.bind(mod .. " + P", hl.dsp.global("quickshell:code"))
hl.bind(mod .. " + B", hl.dsp.global("quickshell:bluetoothmenu"))
hl.bind(mod .. " + T", hl.dsp.global("quickshell:todo-personal"))
hl.bind(mod .. " + O", hl.dsp.global("quickshell:notes"))
hl.bind(mod .. " + I", hl.dsp.global("quickshell:capture"))
hl.bind(mod .. " + L", hl.dsp.global("quickshell:panel"))
hl.bind(mod .. " + Escape", hl.dsp.global("quickshell:powermenu"))
hl.bind(mod .. " + SHIFT + T", hl.dsp.global("quickshell:todo-stars"))
hl.bind(mod .. " + K", hl.dsp.global("quickshell:keyboard"))

-- utils
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd(DOTS .. "/scripts/reload-shell.sh"))
hl.bind(mod .. " + SHIFT + B", hl.dsp.global("quickshell:wallpaper"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.global("quickshell:cursormenu"))
hl.bind(mod .. " + SHIFT + L", hl.dsp.exec_cmd(DOTS .. "/scripts/lock.sh"))
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))

-- screenshot / record
hl.bind("CTRL + SHIFT + 4", hl.dsp.exec_cmd(DOTS .. "/scripts/screenshot.sh"))
hl.bind("CTRL + SHIFT + 3", hl.dsp.exec_cmd(DOTS .. "/scripts/screenshot-full.sh"))
hl.bind("CTRL + SHIFT + L", hl.dsp.exec_cmd(DOTS .. "/scripts/record.sh"))
hl.bind("CTRL + SHIFT + P", hl.dsp.global("quickshell:screenrecord"))

-- session
hl.bind(mod .. " + SHIFT + O", hl.dsp.exec_cmd(DOTS .. "/scripts/session.sh"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd(DOTS .. "/scripts/close-session.sh"))

-- window managment
hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + C", hl.dsp.global("quickshell:clear-or-center"))

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
    hl.exec_cmd("qs ipc call hypr refresh") -- bar workspace pills go stale otherwise
end)

-- mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- fn key functions
hl.bind("XF86AudioRaiseVolume", hl.dsp.global("quickshell:volume-up"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.global("quickshell:volume-down"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.global("quickshell:volume-mute"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.global("quickshell:media-play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.global("quickshell:media-play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.global("quickshell:media-next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.global("quickshell:media-prev"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.global("quickshell:brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("quickshell:brightness-down"),
    { locked = true, repeating = true })
