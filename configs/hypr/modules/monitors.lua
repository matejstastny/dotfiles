hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x400",   scale = 1.60 })
hl.monitor({ output = "DP-1",  mode = "preferred", position = "1600x0", scale = 1.5  })

-- Auto-fix Apple DCP valid_mode:0 race (DP-1 appears black on connect)
hl.on("monitor.added", function(monitor)
    if monitor.name ~= "DP-1" then return end
    hl.exec_cmd("sh -c 'sleep 2 && ~/dotfiles/bin/fix-dp1'")
end)
