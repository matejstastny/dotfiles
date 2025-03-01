return {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
        -- Override only one option (e.g., changing the theme)
        opts.options.theme = "material"
    end,
}
