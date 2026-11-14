hl.monitor({ output = "eDP-1", mode = "2560x1664@60.00", position = "0x160", scale = 1.60, disabled = false })
hl.monitor({ output = "DP-1", mode = "preferred", position = "1600x0", scale = 1.50, disabled = false })

-- the portable sim one
hl.monitor({ output = "desc:XYM M156F1", mode = "preferred", position = "-1920x140", scale = 1.0 })

-- auto fix apple dcp valid_mode:0 race on any external monitor hotplug
hl.on("monitor.added", function(monitor)
    if monitor.name == "eDP-1" then return end
    hl.exec_cmd("sh -c 'sleep 2 && ~/dotfiles/scripts/fix-monitor-mode.sh " .. monitor.name .. "'")
end)
