-- keybinds cheatsheet that opens on leader key trigger

return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 500
    end,
    opts = {
        win = {
            border = "rounded",
        },
    },
}
