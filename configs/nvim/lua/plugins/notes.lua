return {
    {
        "obsidian-nvim/obsidian.nvim",
        version = "*",
        ft = "markdown",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            workspaces = {
                { name = "notes", path = "~/notes" },
            },
            daily_notes = {
                folder = "daily",
                date_format = "%Y-%m-%d",
            },
            legacy_commands = false,
            picker = {
                name = "telescope.nvim",
            },
            -- leave visual concealing off until the vault theme is riced
            ui = { enable = false },
        },
    },
}
