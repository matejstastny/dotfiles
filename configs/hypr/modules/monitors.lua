hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x400", scale = 1.60 })

-- main (samsung via hdmi-in adapter, shows as LGI RB65-HDMI-IN)
hl.monitor({ output = "desc:LGI RB65-HDMI-IN", mode = "preferred", position = "1600x0", scale = 1.5 })

-- the portable sim one
hl.monitor({ output = "desc:XYM M156F1", mode = "preferred", position = "1600x0", scale = 1.0 })

-- auto fix apple dcp valid_mode:0 race
hl.on("monitor.added", function(monitor)
    if not string.find(monitor.description, "RB65") then return end
    hl.exec_cmd("sh -c 'sleep 2 && ~/dotfiles/bin/fix-dp1'")
end)
