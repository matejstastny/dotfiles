hl.config({
    general = {
        gaps_in          = 4,
        gaps_out         = 8,
        border_size      = 2,
        col              = {
            active_border   = "rgba(7c5cbfff)",
            inactive_border = "rgba(1c1528aa)",
        },
        layout           = "dwindle",
        resize_on_border = true,
        allow_tearing    = true,
    },
    decoration = {
        rounding = 8,
        shadow   = { enabled = false },
        blur     = { enabled = true, size = 6, passes = 2, new_optimizations = true },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        disable_hyprland_logo   = true,
        force_default_wallpaper = 0,
    },
    render = {
        direct_scanout = true,
    },
})

hl.curve("snappy", { type = "bezier", points = { { 0.2, 1 }, { 0.2, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "snappy" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "snappy", style = "slide" })
