-- https://github.com/ellisonleao/gruvbox.nvim (current)

return {
    "ellisonleao/gruvbox.nvim",
    name = "gruvbox",
    lazy = false,
    priority = 1000,

    config = function()
        require("gruvbox").setup({
            transparent_mode = true
        })
        vim.cmd("colorscheme gruvbox")
    end,
}
