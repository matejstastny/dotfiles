return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        main = "nvim-treesitter",
        opts = {
            ensure_installed = { "bash", "python", "lua", "vim", "vimdoc", "markdown" },
            highlight        = { enable = true },
            indent           = { enable = true },
        },
    },

    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },

    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        config = true,
    },

    {
        "numToStr/Comment.nvim",
        event = { "BufReadPost", "BufNewFile" },
        config = true,
    },
}
