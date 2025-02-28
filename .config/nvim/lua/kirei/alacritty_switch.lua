local config1 = vim.fn.expand("~/.config/alacritty/nvim.toml")
local config2 = vim.fn.expand("~/.config/alacritty/main.toml")
local main_config = vim.fn.expand("~/.config/alacritty/alacritty.toml")

local function copy_config(src, dest)
    if vim.fn.filereadable(src) == 1 then
        local cmd = string.format("cp %s %s", src, dest)
        os.execute(cmd)
    else
        print("Error: Config file not found - " .. src)
    end
end

local function toggle_tmux_status(enable)
    local status = enable and "on" or "off"
    local cmd = string.format("tmux set-option status %s", status)
    os.execute(cmd)

    if not enable then
        os.execute("tmux refresh-client -S")
    end
end

local function delayed_tmux_toggle(enable)
    vim.defer_fn(function()
        toggle_tmux_status(enable)
    end, 100)
end

-- Handle Neovim startup
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        copy_config(config1, main_config)
        --delayed_tmux_toggle(false) -- Disable tmux status bar and reclaim space
    end
})

-- Handle Neovim exit (explicit delayed handling for restore)
vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        copy_config(config2, main_config)
        --os.execute("tmux set-option status on")
    end
})
