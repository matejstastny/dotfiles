local config1 = "~/.config/alacritty/nvim.toml"
local config2 = "~/.config/alacritty/main.toml"
local main_config = "~/.config/alacritty/alacritty.toml"

local function copy_config(src, dest)
    os.execute("cp " .. src .. " " .. dest)
end

local function toggle_tmux_status(enable)
    local command = enable and "tmux set status on" or "tmux set status off"
    os.execute(command)
end

-- Copy config1 on Neovim start and enable tmux status bar
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        copy_config(config1, main_config)
        toggle_tmux_status(false)
    end
})

-- Copy config2 on Neovim exit and disable tmux status bar
vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
        copy_config(config2, main_config)
        toggle_tmux_status(true)
    end
})
