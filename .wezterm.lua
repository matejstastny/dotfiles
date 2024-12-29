-- Wezterm api
local wezterm = require("wezterm")

-- Variable for the config
local config = wezterm.config_builder()

-- CONFIG
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 12

config.enable_tab_bar = false
config.window_decorations = "NONE"
config.initial_rows = 65
config.initial_cols = 230

config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50

-- Keep at the bottom!
return config

