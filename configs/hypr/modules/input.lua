hl.config({
    input = {
        kb_layout     = "us",
        kb_options    = "ctrl:swap_lwin_lctl",
        follow_mouse  = 1,
        touchpad      = {
            natural_scroll       = true,
            tap_to_click         = true,
            drag_lock            = true,
            clickfinger_behavior = true,
            disable_while_typing = false,
        },
        repeat_delay  = 190,
        repeat_rate   = 30,
        sensitivity   = 0.1,
        accel_profile = "flat",
    },
})

-- Magic Mouse sensitivity (tune this value: -1.0 to 1.0, or accel_profile = "flat"/"adaptive")
-- scroll_factor multiplies scroll speed (default 1.0, tune to taste)
hl.device({ name = "matěj’s-magic-mouse", sensitivity = -0.3, accel_profile = "flat", scroll_factor = 2.0, natural_scroll = false })

-- Windows keyboard remapped to feel like Mac
hl.device({ name = "keychron-keychron-k1-se", kb_options = "ctrl:swap_lalt_lctl_lwin" })
hl.device({ name = "keychron-keychron-k1-se-2", kb_options = "ctrl:swap_lalt_lctl_lwin" })

-- 3-finger swipe to switch workspaces (like yabai/macOS)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
