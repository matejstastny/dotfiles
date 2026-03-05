return {
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
        },
        opts = {
            cmdline = {
                view = "cmdline_popup",
                format = {
                    cmdline   = { icon = ">" },
                    search_up = { icon = "/" },
                    search_down = { icon = "?" },
                },
            },
            messages = { enabled = false },
            notify   = { enabled = false },
            lsp = {
                progress = { enabled = false },
                hover    = { enabled = false },
                signature = { enabled = false },
            },
            views = {
                cmdline_popup = {
                    position = { row = "40%", col = "50%" },
                    size     = { width = 60, height = "auto" },
                    border   = { style = "rounded" },
                    win_options = {
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
                    },
                },
            },
        },
    },

    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "night",
                transparent = true,
                styles = {
                    comments = { italic = true },
                    keywords = { italic = false },
                },
            })
            vim.cmd("colorscheme tokyonight-night")
        end,
    },

    {
        "nvim-lualine/lualine.nvim",
        lazy = false,
        config = function()
            -- tmux-dotbar palette
            local dim   = "#4A595C"
            local text  = "#BFBDB6"
            local cyan  = "#39BAE6"
            local mid   = "#565B66"
            local bg    = "NONE"

            local theme = {
                normal   = {
                    a = { fg = "#1A1F29", bg = cyan, gui = "bold" },
                    b = { fg = text, bg = mid },
                    c = { fg = text, bg = bg },
                },
                insert   = { a = { fg = "#1A1F29", bg = "#A8CC7C", gui = "bold" }, b = { fg = text, bg = mid }, c = { fg = text, bg = bg } },
                visual   = { a = { fg = "#1A1F29", bg = "#C2A35E", gui = "bold" }, b = { fg = text, bg = mid }, c = { fg = text, bg = bg } },
                replace  = { a = { fg = "#1A1F29", bg = "#F07178", gui = "bold" }, b = { fg = text, bg = mid }, c = { fg = text, bg = bg } },
                command  = { a = { fg = "#1A1F29", bg = cyan, gui = "bold" }, b = { fg = text, bg = mid }, c = { fg = text, bg = bg } },
                inactive = {
                    a = { fg = dim, bg = bg },
                    b = { fg = dim, bg = bg },
                    c = { fg = dim, bg = bg },
                },
            }

            require("lualine").setup({
                options = {
                    theme                = theme,
                    component_separators = { left = "·", right = "·" },
                    section_separators   = { left = "", right = "" },
                    globalstatus         = true,
                },
                sections = {
                    lualine_a = { { "mode", fmt = function(s) return s:sub(1, 1) end } },
                    lualine_b = {
                        { "branch" },
                        {
                            "diff",
                            symbols = { added = "+ ", modified = "~ ", removed = "- " },
                            diff_color = {
                                added    = { fg = "#A8CC7C" },
                                modified = { fg = "#C2A35E" },
                                removed  = { fg = "#F07178" },
                            },
                        },
                    },
                    lualine_c = { { "filename", symbols = { modified = " *", readonly = " ", unnamed = "[No Name]" } } },
                    lualine_x = {
                        {
                            "diagnostics",
                            sources = { "nvim_lsp" },
                            sections = { "error", "warn" },
                            symbols = { error = "E:", warn = "W:" },
                        },
                    },
                    lualine_y = { "filetype" },
                    lualine_z = { { "location", fmt = function(s) return "Ln " .. s:gsub(":", ", Col ") end } },
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { "filename" },
                    lualine_x = { "location" },
                    lualine_y = {},
                    lualine_z = {},
                },
            })
        end,
    },
}
