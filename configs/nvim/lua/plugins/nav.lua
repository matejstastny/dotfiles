return {
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("telescope").setup({
                defaults = {
                    layout_strategy = "horizontal",
                    sorting_strategy = "ascending",
                    layout_config = { prompt_position = "top" },
                },
            })
        end,
    },
}
