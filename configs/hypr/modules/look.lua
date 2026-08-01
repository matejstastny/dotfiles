hl.config({
    general = {
        gaps_in          = 4,
        gaps_out         = 8,
        border_size      = 2,
        col              = {
            active_border   = "rgba(7878c8ff)",
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
    plugin = {
        hy3 = {
            tab_first_window = true,
            tabs = {
                height       = 20,
                padding      = 2,
                from_top     = true,
                radius       = 6,
                border_width = 1,
                render_text  = true,
                text_font    = "Maple Mono NF",
                text_height  = 8,
                text_padding = 6,
                opacity      = 0.8,
                colors       = {
                    active                    = "rgba(25253aff)",
                    active_border             = "rgba(7878c8ff)",
                    active_text               = "rgba(dce0f4ff)",
                    active_alt_monitor        = "rgba(181825ff)",
                    active_alt_monitor_border = "rgba(7878c866)",
                    active_alt_monitor_text   = "rgba(9898c0ff)",
                    focused                   = "rgba(181825ff)",
                    focused_border            = "rgba(7878c8aa)",
                    focused_text              = "rgba(9898c0ff)",
                    inactive                  = "rgba(11111bff)",
                    inactive_border           = "rgba(25253aff)",
                    inactive_text             = "rgba(3d3d5cff)",
                },
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

hl.curve("snappy", { type = "bezier", points = { { 0.2, 1 }, { 0.2, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "snappy" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "snappy", style = "slide" })
