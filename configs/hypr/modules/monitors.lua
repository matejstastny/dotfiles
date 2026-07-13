hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x400", scale = 1.60 })

-- Samsung: plug it in, run `hyprctl monitors`, copy the `description:` line, replace below
hl.monitor({ output = "desc:Samsung ...", mode = "preferred", position = "1600x0", scale = 1.5 })

-- XYM portable M156F1 (1080p 15.6")
hl.monitor({ output = "desc:XYM M156F1", mode = "preferred", position = "1600x0", scale = 1.0 })

-- auto fix apple dcp valid_mode:0 race (Samsung only)
hl.on("monitor.added", function(monitor)
    if not string.find(monitor.description, "Samsung") then return end
    hl.exec_cmd("sh -c 'sleep 2 && ~/dotfiles/bin/fix-dp1'")
end)
