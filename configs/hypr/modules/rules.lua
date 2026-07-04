hl.on("window.open", function(window)
    if window.class:find("^blueman") then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ exact = true, x = 400, y = 600 }))
        hl.dispatch(hl.dsp.window.center())
    end
    if window.class:find("chrome%-nngceckbapebfimnlniiiahkandclblb") then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.resize({ exact = true, x = 400, y = 600 }))
        hl.dispatch(hl.dsp.window.center())
    end
end)

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
