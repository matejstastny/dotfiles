return {
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
        },
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                defaults = {
                    layout_strategy  = "horizontal",
                    sorting_strategy = "ascending",
                    layout_config    = { prompt_position = "top", preview_width = 0.55 },
                    prompt_prefix    = "✦ ",
                    selection_caret  = "  ",
                    path_display     = { "truncate" },
                    file_ignore_patterns = { "%.git/", "node_modules/", "%.venv/", "__pycache__/" },
                },
                pickers = {
                    find_files = { hidden = true },
                },
                extensions = {
                    ["ui-select"] = { require("telescope.themes").get_dropdown() },
                },
            })
            telescope.load_extension("ui-select")
        end,
    },
}
