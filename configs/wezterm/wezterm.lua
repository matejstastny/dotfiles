local wezterm = require 'wezterm'
local act     = wezterm.action
local config  = wezterm.config_builder()

-- pallete --------------------------------------------------------------
local P       = {
    bg     = '#11111b',
    bg1    = '#181825',
    bg2    = '#25253a',
    bg3    = '#3d3d5c',
    fg     = '#dce0f4',
    dim    = '#9898c0',
    purple = '#7878c8',
    lila   = '#9898e0',
    pink   = '#c47ab8',
    teal   = '#7abfc4',
    blue   = '#7a9bbf',
    yell   = '#c4a87a',
    white  = '#f0f0ff',
}


config.colors                       = {
    foreground    = P.fg,
    background    = P.bg,
    cursor_bg     = P.purple,
    cursor_border = P.purple,
    cursor_fg     = P.bg,
    selection_bg  = P.bg3,
    selection_fg  = P.white,
    ansi          = { P.bg1, P.pink, P.blue, P.yell, P.purple, P.pink, P.teal, P.fg },
    brights       = { P.bg3, '#d48fc8', '#8fb8d8', '#d4b890', P.lila, '#d494cc', '#90d0d4', P.white },
    tab_bar       = {
        background         = P.bg,
        active_tab         = { bg_color = P.purple, fg_color = P.white, intensity = 'Bold' },
        inactive_tab       = { bg_color = P.bg1, fg_color = P.dim },
        inactive_tab_hover = { bg_color = P.bg2, fg_color = P.fg },
        new_tab            = { bg_color = P.bg, fg_color = P.dim },
        new_tab_hover      = { bg_color = P.bg1, fg_color = P.fg },
    },
}

-- font & window --------------------------------------------------------

config.font                         = wezterm.font_with_fallback {
    { family = 'Maple Mono NF', weight = 'Regular' },
}
config.font_size                    = 9.0
config.line_height                  = 1.1

config.window_background_opacity    = 0.88
config.window_padding               = { left = 12, right = 12, top = 12, bottom = 12 }
config.window_decorations           = 'NONE'
config.window_close_confirmation    = 'NeverPrompt'

config.default_cursor_style         = 'BlinkingBar'
config.cursor_blink_rate            = 500
config.scrollback_lines             = 10000
config.audible_bell                 = 'Disabled'

-- tabbar
config.use_fancy_tab_bar            = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom            = false
config.tab_max_width                = 28
config.default_workspace            = 'main'

-- show cwd basename as tab title
wezterm.on('format-tab-title', function(tab)
    local title = tab:get_title()
    if title ~= '' then
        return ' ' .. title .. ' '
    end
    local pane = tab:active_pane()
    local cwd  = pane:get_current_working_dir()
    if cwd then
        local name = cwd.file_path:match('([^/]+)/?$') or cwd.file_path
        return ' ' .. name .. ' '
    end
    local proc = pane:get_foreground_process_name()
    return ' ' .. (proc:match('([^/]+)$') or proc) .. ' '
end)

-- status bar -----------------------------------------------------------

wezterm.on('update-status', function(window, pane)
    local ws = window:active_workspace()

    window:set_left_status(wezterm.format {
        { Foreground = { Color = P.purple } },
        { Attribute = { Intensity = 'Bold' } },
        { Text = '  ' .. ws .. ' ' },
        { Attribute = { Intensity = 'Normal' } },
        { Foreground = { Color = P.bg3 } },
        { Text = ' ✦ ' },
    })

    local cwd = pane:get_current_working_dir()
    local dir = ''
    if cwd then
        dir = cwd.file_path:gsub(os.getenv('HOME'), '~')
    end

    window:set_right_status(wezterm.format {
        { Foreground = { Color = P.dim } },
        { Text = dir .. '  ' },
    })
end)

-- project switcher -----------------------------------------------------

local function pick_project(window, pane)
    local home    = os.getenv('HOME')
    local history = home .. '/.local/share/vscode-projects'

    local choices = {}
    local seen    = {}

    -- Always include dotfiles first
    table.insert(choices, {
        id    = home .. '/dotfiles',
        label = wezterm.format {
            { Attribute = { Intensity = 'Bold' } }, { Foreground = { Color = P.fg } }, { Text = 'dotfiles' },
            { Attribute = { Intensity = 'Normal' } }, { Foreground = { Color = P.dim } }, { Text = '  ~/dotfiles' },
        },
    })
    seen[home .. '/dotfiles'] = true

    local f = io.open(history, 'r')
    if f then
        for line in f:lines() do
            local path = line:gsub('^~', home)
            if path ~= '' and not seen[path] then
                seen[path] = true
                local name = path:match('([^/]+)/?$') or path
                table.insert(choices, {
                    id    = path,
                    label = wezterm.format {
                        { Attribute = { Intensity = 'Bold' } }, { Foreground = { Color = P.fg } }, { Text = name },
                        { Attribute = { Intensity = 'Normal' } }, { Foreground = { Color = P.dim } }, { Text = '  ' .. path:gsub(home, '~') },
                    },
                })
            end
        end
        f:close()
    end

    window:perform_action(
        act.InputSelector {
            title   = '  Projects',
            fuzzy   = true,
            choices = choices,
            action  = wezterm.action_callback(function(win, _, id, _)
                if not id then return end
                local name = id:match('([^/]+)/?$') or id
                win:perform_action(
                    act.SwitchToWorkspace { name = name, spawn = { cwd = id } },
                    pane
                )
            end),
        },
        pane
    )
end

-- binds ----------------------------------------------------------------

config.disable_default_key_bindings = true

config.keys = {
    { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
    { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },

    { key = '|', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = '-', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

    { key = 'h', mods = 'CTRL',       action = act.ActivatePaneDirection 'Left' },
    { key = 'j', mods = 'CTRL',       action = act.ActivatePaneDirection 'Down' },
    { key = 'k', mods = 'CTRL',       action = act.ActivatePaneDirection 'Up' },
    { key = 'l', mods = 'CTRL',       action = act.ActivatePaneDirection 'Right' },

    { key = 'h', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize { 'Left', 3 } },
    { key = 'j', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize { 'Down', 3 } },
    { key = 'k', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize { 'Up', 3 } },
    { key = 'l', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize { 'Right', 3 } },

    { key = 'z', mods = 'CTRL|SHIFT', action = act.TogglePaneZoomState },
    { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = false } },
    { key = 'n', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = '[', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
    { key = ']', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },

    {
        key = 'r',
        mods = 'CTRL|SHIFT',
        action = act.PromptInputLine {
            description = 'Rename tab',
            action      = wezterm.action_callback(function(win, _, line)
                if line and line ~= '' then win:active_tab():set_title(line) end
            end),
        }
    },

    { key = 'o', mods = 'CTRL|SHIFT', action = wezterm.action_callback(pick_project) },
    { key = 'p', mods = 'CTRL|SHIFT', action = act.ShowLauncherArgs { flags = 'WORKSPACES' } },
    { key = 's', mods = 'CTRL|SHIFT', action = act.QuickSelect },
    { key = 'f', mods = 'CTRL|SHIFT', action = act.Search 'CurrentSelectionOrEmptyString' },
    { key = '=', mods = 'CTRL',       action = act.IncreaseFontSize },
    { key = '-', mods = 'CTRL',       action = act.DecreaseFontSize },
    { key = '0', mods = 'CTRL',       action = act.ResetFontSize },
    { key = 'l', mods = 'CTRL',       action = act.SendKey { key = 'l', mods = 'CTRL' } },
}

for i = 1, 9 do
    table.insert(config.keys, {
        key    = tostring(i),
        mods   = 'CTRL|SHIFT',
        action = act.ActivateTab(i - 1),
    })
end

-- mouse ----------------------------------------------------------------

config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = 'Right' } },
        mods = 'NONE',
        action = act.PasteFrom 'PrimarySelection'
    },
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'CTRL',
        action = act.OpenLinkAtMouseCursor
    },
}

config.hyperlink_rules = wezterm.default_hyperlink_rules()

return config
