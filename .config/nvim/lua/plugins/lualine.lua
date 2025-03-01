return {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
        opts.options.theme = "auto"
        opts.options.icons_enabled = true
        opts.options.component_separators = "|"
        opts.options.section_separators = ""
    end,
}
