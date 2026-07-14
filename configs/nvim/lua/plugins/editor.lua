return {
    {
        "nvim-treesitter/nvim-treesitter",
        -- Pin to the stable `master` branch: its classic setup (highlight/indent
        -- via `nvim-treesitter.configs`) is what this config relies on.
        branch = "master",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "bash", "python", "lua", "vim", "vimdoc", "query",
                    "markdown", "markdown_inline", "regex", "diff", "gitcommit",
                    "javascript", "typescript", "tsx", "html", "css",
                    "json", "jsonc", "yaml", "toml",
                    "rust", "go", "gomod", "c", "cpp",
                },
                auto_install = true,
                highlight = { enable = true },
                indent    = { enable = true },
            })
        end,
    },

    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },

    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            signs = {
                add          = { text = "▎" },
                change       = { text = "▎" },
                delete       = { text = "" },
                topdelete    = { text = "" },
                changedelete = { text = "▎" },
                untracked    = { text = "▎" },
            },
        },
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
            popup_border_style   = "rounded",
            window = { width = 30 },
            filesystem = {
                filtered_items = {
                    hide_dotfiles   = false,
                    hide_gitignored = false,
                },
                follow_current_file      = { enabled = true },
                use_libuv_file_watcher   = true,
            },
            default_component_configs = {
                indent = { with_expanders = true },
                git_status = {
                    symbols = {
                        added    = "",
                        modified = "",
                        deleted  = "✖",
                        renamed  = "󰁕",
                        untracked = "",
                        ignored   = "",
                        unstaged  = "󰄱",
                        staged    = "",
                        conflict  = "",
                    },
                },
            },
        },
    },

    -- Keybind hint popup
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "modern",
            spec = {
                { "<leader>c", group = "code / lsp" },
                { "<leader>f", group = "find" },
                { "<leader>g", group = "git" },
                { "<leader>n", group = "notes" },
                { "<leader>r", group = "rename" },
            },
        },
    },

    -- Indent guides
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

    -- Highlight all instances of the word under the cursor
    {
        "RRethy/vim-illuminate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("illuminate").configure({
                delay = 150,
                large_file_cutoff = 2000,
                filetypes_denylist = { "neo-tree", "TelescopePrompt", "dashboard", "snacks_dashboard" },
            })
        end,
    },
}
