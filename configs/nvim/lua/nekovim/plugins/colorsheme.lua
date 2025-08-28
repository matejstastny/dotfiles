-- https://github.com/bluz71/vim-moonfly-colors (current)

return {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,

    config = function()
        vim.g.moonflyTransparent = true
        vim.cmd([[colorscheme moonfly]])
    end,
}
