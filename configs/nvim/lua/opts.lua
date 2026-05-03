local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2

opt.scrolloff = 8
opt.termguicolors = true
opt.signcolumn = "yes"
opt.clipboard = "unnamedplus"
opt.undofile = true

opt.ignorecase = true
opt.smartcase = true

opt.splitright = true
opt.splitbelow = true

opt.wrap = true
opt.whichwrap = "b,s,h,l,<,>,[,]"
opt.cursorline = true

if vim.g.neovide then
    vim.g.neovide_opacity = 0.92
    vim.g.neovide_window_blurred = true
    vim.g.neovide_floating_blur_amount_x = 3.0
    vim.g.neovide_floating_blur_amount_y = 3.0
    vim.g.neovide_scroll_animation_length = 0.2
    vim.g.neovide_cursor_vfx_mode = "railgun"
    vim.g.neovide_cursor_animate_in_insert_mode = true
    vim.o.guifont = "JetBrainsMono Nerd Font Mono:h16"
end
