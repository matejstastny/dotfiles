hl.config({
    general = {
        gaps_in          = 4,
        gaps_out         = 8,
        border_size      = 2,
        col              = {
            active_border   = { colors = { "rgba(7878c8ff)", "rgba(c47ab8ff)" }, angle = 45 },
            inactive_border = "rgba(25253aaa)",
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
    group = {
        auto_group = false,
        col = {
            border_active   = "rgba(7878c8ff)",
            border_inactive = "rgba(25253aff)",
        },
        groupbar = {
            height                     = 20,
            gaps_in                    = 2,
            gaps_out                   = 2,
            gradients                  = true,
            gradient_round_only_edges  = false,
            gradient_rounding          = 10,
            indicator_height           = 0,
            render_titles              = true,
            font_family                = "Maple Mono NF",
            font_size                  = 10,
            font_weight_active         = "bold",
            font_weight_inactive       = "medium",
            text_padding               = 6,
            text_color                 = "rgba(dce0f4ff)",
            text_color_inactive        = "rgba(3d3d5cff)",
            col                        = {
                active   = "rgba(25253aff)",
                inactive = "rgba(11111bff)",
            },
        },
    },
    misc = {
        disable_hyprland_logo   = true,
        force_default_wallpaper = 0,
    },
    xwayland = {
        force_zero_scaling = true,
    },
    render = {
        direct_scanout = true,
    },
})

hl.curve("snap", { type = "bezier", points = { { 0.12, 0 }, { 0.08, 1 } } })
hl.curve("pop", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } })
hl.curve("swoosh", { type = "bezier", points = { { 0.22, 1.12 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 5.5, bezier = "snap" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.6, bezier = "snap" })
hl.animation({ leaf = "windowsIn", enabled = false })
hl.animation({ leaf = "windowsOut", enabled = false })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.6, bezier = "snap" })
hl.animation({ leaf = "fade", enabled = false })
hl.animation({ leaf = "border", enabled = true, speed = 5.3, bezier = "snap" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 25, bezier = "linear", style = "loop" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.7, bezier = "swoosh", style = "slide" })
