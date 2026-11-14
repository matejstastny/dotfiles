-- ===========================================================================
-- workspace layouts
-- ===========================================================================
-- see looks.lua
hl.workspace_rule({ workspace = "2", layout = "hy3" })
hl.workspace_rule({ workspace = "4", layout = "hy3" })
hl.workspace_rule({ workspace = "7", layout = "hy3" })

-- ===========================================================================
-- session apps: pin each to its workspace on launch (see scripts/session.sh)
-- ===========================================================================

-- 1: terminal
hl.window_rule({ name = "session-ws-kitty", match = { class = "^kitty$" }, workspace = "1 silent" })

-- 2: editors
hl.window_rule({ name = "session-ws-codium", match = { class = "^codium$" }, workspace = "2 silent" })
hl.window_rule({ name = "session-ws-code", match = { class = "^com.microsoft.VSCode$" }, workspace = "2 silent" })

-- 3: browser
hl.window_rule({ name = "session-ws-helium", match = { class = "^helium$" }, workspace = "3 silent" })

-- 4: chat
hl.window_rule({ name = "session-ws-vesktop", match = { class = "^vesktop$" }, workspace = "4 silent" })
hl.window_rule({ name = "session-ws-halloy", match = { class = "^org.squidowl.halloy$" }, workspace = "4 silent" })
hl.window_rule({ name = "session-ws-whatsie", match = { class = "^com.ktechpit.whatsie$" }, workspace = "4 silent" })

-- 5: music
hl.window_rule({ name = "session-ws-spotifast", match = { class = "^spotifast$" }, workspace = "5 silent" })

-- 6: t3 code
hl.window_rule({ name = "session-ws-t3code", match = { class = "^t3code$" }, workspace = "6 silent" })

-- 7: notes + games + sim
hl.window_rule({ name = "session-ws-obsidian", match = { class = "^obsidian$" }, workspace = "7 silent" })
hl.window_rule({ name = "session-ws-steam", match = { class = "^steam$" }, workspace = "7 silent" })

-- 9: stars
hl.window_rule({ name = "session-ws-stars", match = { class = "^helium-stars$" }, workspace = "9 silent" })

-- ===========================================================================
-- native file dialogs: float, centered, fixed size
-- ===========================================================================
local file_dialogs = {
    { name = "save-file-float",     title = "Save File" },
    { name = "open-files-float",    title = "Open Files" },
    { name = "select-folder-float", title = "Select Folder" },
}
for _, dialog in ipairs(file_dialogs) do
    hl.window_rule({
        name = dialog.name,
        match = { title = "^" .. dialog.title .. "$" },
        float = true,
        center = true,
        size = "70% 75%",
    })
end

-- ===========================================================================
-- dynamic float + resize + center on open
-- ===========================================================================
hl.on("window.open", function(window)
    -- bluetooth window
    if window.class:find("^blueman") then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ exact = true, x = 400, y = 600 }))
        hl.dispatch(hl.dsp.window.center())
        return
    end

    -- audio window
    if window.class:find("^org.pulseaudio.pavucontrol") then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ exact = true, x = 600, y = 800 }))
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

-- ===========================================================================
-- restore wallpaper on monitor hotplug
-- ===========================================================================
hl.on("monitor.added", function(monitor)
    hl.exec_cmd("/home/elara/dotfiles/scripts/wallpaper-restore.sh " .. monitor.name)
end)

-- ===========================================================================
-- ros / sim tooling
-- ===========================================================================

-- workspace 7: gazebo + rviz autotab into one hy3 tab group (rule in look.lua),
-- nothing else on ws7 gets pulled into it
hl.window_rule({ name = "gazebo-workspace", match = { class = "^Gazebo GUI$" }, workspace = "7" })
hl.window_rule({ name = "gazebo-scroll", match = { class = "^Gazebo GUI$" }, scroll_touchpad = 0.1 })
hl.window_rule({ name = "rviz-workspace", match = { class = "^rviz2$" }, workspace = "7 silent" })

hl.window_rule({ name = "chrono-sim", match = { class = "^vsg::Windo$" }, workspace = "7" })
hl.window_rule({ name = "qgc-workspace", match = { class = "^QGroundControl$" }, workspace = "8 silent" })

hl.window_rule({ name = "tigervnc-workspace", match = { class = "^Vncviewer$" }, workspace = "7 silent" })
hl.window_rule({ name = "tigervnc-float", match = { class = "^Vncviewer$" }, float = true, center = true })

hl.window_rule({ name = "joint-gui-workspace", match = { class = "^Tk$", title = "^Joint GUI$" }, workspace = "3 silent" })
hl.window_rule({ name = "joint-gui-float", match = { class = "^Tk$", title = "^Joint GUI$" }, float = true })
hl.window_rule({ name = "joint-gui-size", match = { class = "^Tk$", title = "^Joint GUI$" }, size = "420 191" })
hl.window_rule({ name = "joint-gui-position", match = { class = "^Tk$", title = "^Joint GUI$" }, move = "596 340" })

-- controller_gui: floats on top of the gazebo/rviz hy3 tab group, bottom-right of ws7.
-- `float = true` already renders above the tiled layer, so no separate "on top" rule.
-- move/size are hardcoded pixels tuned for eDP-1 (2560x1664 @ 1.60 scale -> 1600x1040
-- logical), same tradeoff the joint-gui rule below already makes for its own monitor.
-- title must match exactly (a "^Controller GUI" prefix silently matched nothing in this
-- hl binding) - if the window's title changes (it lists its key bindings, so it grows as
-- more get added), update this string and re-measure size/move with `hyprctl clients -j`.
local controller_gui_match = { class = "^Tk$", title = "^Controller GUI - WASD / Arrows / Q,E / Space$" }
hl.window_rule({ name = "controller-gui-workspace", match = controller_gui_match, workspace = "7" })
hl.window_rule({ name = "controller-gui-float", match = controller_gui_match, float = true })
hl.window_rule({ name = "controller-gui-size", match = controller_gui_match, size = "270 189" })
hl.window_rule({ name = "controller-gui-position", match = controller_gui_match, move = "1310 804" })

-- ===========================================================================
-- other rules
-- ===========================================================================
hl.window_rule({
    name = "minecraft-immediate",
    match = { class = "^Minecraft.*$" },
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
