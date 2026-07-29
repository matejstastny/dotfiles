-- workspace 2 uses hy3
hl.workspace_rule({ workspace = "2", layout = "hy3" })

-- workspace assignments
hl.window_rule({ name = "session-ws-kitty", match = { class = "^kitty$" }, workspace = "1 silent" })
hl.window_rule({ name = "session-ws-codium", match = { class = "^codium$" }, workspace = "2 silent" })
hl.window_rule({ name = "session-ws-code", match = { class = "^code$" }, workspace = "2 silent" })
hl.window_rule({ name = "session-ws-helium", match = { class = "^helium$" }, workspace = "3 silent" })
hl.window_rule({ name = "session-ws-vesktop", match = { class = "^vesktop$" }, workspace = "4 silent" })
hl.window_rule({ name = "session-ws-obsidian", match = { class = "^obsidian$" }, workspace = "5 silent" })
hl.window_rule({ name = "session-ws-t3code", match = { class = "^t3code$" }, workspace = "6 silent" })

-- file dialogs
hl.window_rule({ name = "save-file-float", match = { title = "^Save File$" }, float = true, center = true })
hl.window_rule({ name = "open-files-float", match = { title = "^Open Files$" }, float = true, center = true })
hl.window_rule({ name = "select-folder-float", match = { title = "^Select Folder$" }, float = true, center = true })

-- merge a window into the ws2 hy3 tab group, preserving the active workspace
local function ws2_tab(window)
    local prev_ws = hl.get_active_workspace()
    hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
    hl.dispatch(hl.plugin.hy3.change_group('tab'))
    if prev_ws and prev_ws.id ~= 2 then
        hl.dispatch(hl.dsp.focus({ workspace = prev_ws.id }))
    end
end

hl.on("window.open", function(window)
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

    if window.workspace and window.workspace.id == 2 then
        ws2_tab(window)
    end
end)

-- also handle windows moved to ws2 after creation (alt+shift+2 etc.)
hl.on("window.move_to_workspace", function(window)
    if window.workspace and window.workspace.id == 2 then
        ws2_tab(window)
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
    name = "swayosd-noblur",
    match = { namespace = "swayosd" },
    blur = false,
})

-- ros sim tools
hl.window_rule({ name = "chrono-sim", match = { class = "^vsg::Windo$" }, workspace = "7" })
hl.window_rule({ name = "gazebo-workspace", match = { class = "^Gazebo GUI$" }, workspace = "7" })
hl.window_rule({ name = "tigervnc-workspace", match = { class = "^Vncviewer$" }, workspace = "7 silent" })
hl.window_rule({ name = "tigervnc-float", match = { class = "^Vncviewer$" }, float = true, center = true })
hl.window_rule({
    name = "joint-gui-workspace",
    match = { class = "^Tk$", title = "^Joint GUI$" },
    workspace = "7 silent",
})
hl.window_rule({ name = "joint-gui-float", match = { class = "^Tk$", title = "^Joint GUI$" }, float = true })
hl.window_rule({ name = "joint-gui-size", match = { class = "^Tk$", title = "^Joint GUI$" }, size = "420 191" })
hl.window_rule({ name = "joint-gui-topleft", match = { class = "^Tk$", title = "^Joint GUI$" }, move = "8 46" })
hl.window_rule({ name = "rviz-workspace", match = { class = "^rviz2$" }, workspace = "8 silent" })

hl.window_rule({ name = "gazebo-scroll", match = { class = "^Gazebo GUI$" }, scroll_touchpad = 0.1 })

-- lazygit floating window
hl.window_rule({ name = "lazygit-float", match = { class = "^lazygit$" }, float = true })
hl.window_rule({ name = "lazygit-size", match = { class = "^lazygit$" }, size = "1300 800" })
hl.window_rule({ name = "lazygit-center", match = { class = "^lazygit$" }, center = true })

-- other rules
hl.window_rule({
    name = "minecraft-immediate",
    match = { class = "^Minecraft" },
    immediate = true,
})
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
