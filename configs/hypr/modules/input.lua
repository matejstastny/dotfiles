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

-- magic mouse
hl.device({ name = "matěj’s-magic-mouse", sensitivity = -0.3, accel_profile = "flat", scroll_factor = 2.0, natural_scroll = false })

-- mac keyboard
hl.device({ name = "keychron-keychron-k1-se", kb_options = "ctrl:swap_lalt_lctl_lwin" })
hl.device({ name = "keychron-keychron-k1-se-2", kb_options = "ctrl:swap_lalt_lctl_lwin" })

-- 3-finger swipe
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
