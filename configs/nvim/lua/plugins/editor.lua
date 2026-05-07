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

    -- File explorer
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        cmd = "Neotree",
        opts = {
            close_if_last_window = true,
            window = { width = 28 },
            filesystem = {
                filtered_items = {
                    hide_dotfiles   = false,
                    hide_gitignored = false,
                },
                follow_current_file = { enabled = true },
            },
            default_component_configs = {
                indent = { with_expanders = true },
            },
        },
    },

    -- Keybind hint popup
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = { preset = "modern" },
    },

    -- Rainbow indent guides
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            indent = { char = "│" },
            scope  = { enabled = true, show_start = false, show_end = false },
        },
    },

    -- Surround text objects (ys, cs, ds)
    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
        config = true,
    },

    -- Highlight all instances of word under cursor
    {
        "RRethy/vim-illuminate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("illuminate").configure({
                delay = 150,
                large_file_cutoff = 2000,
                filetypes_denylist = { "neo-tree", "TelescopePrompt", "dashboard" },
            })
        end,
    },

    -- Telescope UI select (makes vim.ui.select use telescope)
    {
        "nvim-telescope/telescope-ui-select.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" },
        config = function()
            require("telescope").setup({
                extensions = {
                    ["ui-select"] = { require("telescope.themes").get_dropdown() },
                },
                defaults = {
                    layout_strategy  = "horizontal",
                    sorting_strategy = "ascending",
                    layout_config    = { prompt_position = "top" },
                },
            })
            require("telescope").load_extension("ui-select")
        end,
    },
}
