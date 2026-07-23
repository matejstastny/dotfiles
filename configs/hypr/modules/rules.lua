hl.on("window.open", function(window)
    -- file dialogs: float, center, and stop — prevents class-based rules below from also firing
    if window.title:find("^Save File$") or window.title:find("^Open Files$") or window.title:find("^Select Folder$") then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.center())
        return
    end

    -- workspace assignments
    local ws_map = {
        ["^kitty$"]    = 1,
        ["^codium$"]   = 2,
        ["^helium$"]   = 3,
        ["^vesktop$"]  = 4,
        ["^obsidian$"] = 5,
        ["^t3code$"]   = 6,
    }
    for pattern, ws in pairs(ws_map) do
        if window.class:find(pattern) then
            hl.dispatch(hl.dsp.window.move({ workspace = ws, silent = true }))
            return
        end
    end

    -- bluetooth window
    if window.class:find("^blueman") then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ exact = true, x = 400, y = 600 }))
        hl.dispatch(hl.dsp.window.center())
        return
    end

    -- bitwarden password manager window
    if window.class:find("chrome%-nngceckbapebfimnlniiiahkandclblb") then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ exact = true, x = 400, y = 600 }))
        hl.dispatch(hl.dsp.window.center())
        return
    end
end)

-- restore wallpaper on monitor hotplug
hl.on("monitor.added", function()
    hl.exec_cmd("/home/elara/dotfiles/bin/wallpaper-restore")
end)

-- waypaper
hl.window_rule({ name = "waypaper-float", match = { class = "^waypaper$" }, float = true })
hl.window_rule({ name = "waypaper-size", match = { class = "^waypaper$" }, size = "800 600" })
hl.window_rule({ name = "waypaper-center", match = { class = "^waypaper$" }, center = true })

-- swayosd: disable blur so the transparent window bg doesn't create a liquid-glass circle
hl.layer_rule({
    name  = "swayosd-noblur",
    match = { namespace = "swayosd" },
    blur  = false,
})

-- other rules
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
