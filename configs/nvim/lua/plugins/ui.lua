return {
    {
        "folke/noice.nvim",
        cond = not vim.g.neovide,
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
        },
        opts = {
            cmdline  = {
                view = "cmdline_popup",
                format = {
                    cmdline     = { icon = ">" },
                    search_up   = { icon = "/" },
                    search_down = { icon = "?" },
                },
            },
            messages = { enabled = false },
            notify   = { enabled = false },
            lsp      = {
                progress  = { enabled = false },
                hover     = { enabled = false },
                signature = { enabled = false },
            },
            views    = {
                cmdline_popup = {
                    position    = { row = "40%", col = "50%" },
                    size        = { width = 60, height = "auto" },
                    border      = { style = "rounded" },
                    win_options = {
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
                    },
                },
            },
        },
    },

    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("kanagawa").setup({
                transparent = true,
                theme = "wave",
                commentStyle = { italic = true },
                keywordStyle = { italic = false },
                overrides = function(colors)
                    local theme = colors.theme
                    return {
                        NormalFloat = { bg = "none" },
                        FloatBorder = { bg = "none" },
                        FloatTitle = { bg = "none" },
                        TelescopeNormal = { bg = "none" },
                        TelescopeBorder = { bg = "none" },
                        TelescopePromptNormal = { bg = "none" },
                        TelescopePromptBorder = { bg = "none" },
                        TelescopeResultsNormal = { bg = "none" },
                        TelescopeResultsBorder = { bg = "none" },
                        TelescopePreviewNormal = { bg = "none" },
                        TelescopePreviewBorder = { bg = "none" },
                    }
                end,
            })
            vim.cmd("colorscheme kanagawa-wave")
        end,
    },

    {
        "nvim-lualine/lualine.nvim",
        lazy = false,
        config = function()
            -- kanagawa palette
            local dim    = "#727169"
            local text   = "#DCD7BA"
            local accent = "#7E9CD8"
            local mid    = "#2A2A37"
            local bg     = "NONE"
            local dark   = "#16161D"

            local theme  = {
                normal   = {
                    a = { fg = dark, bg = accent, gui = "bold" },
                    b = { fg = text, bg = mid },
                    c = { fg = text, bg = bg },
                },
                insert   = { a = { fg = dark, bg = "#98BB6C", gui = "bold" }, b = { fg = text, bg = mid }, c = { fg = text, bg = bg } },
                visual   = { a = { fg = dark, bg = "#E6C384", gui = "bold" }, b = { fg = text, bg = mid }, c = { fg = text, bg = bg } },
                replace  = { a = { fg = dark, bg = "#E46876", gui = "bold" }, b = { fg = text, bg = mid }, c = { fg = text, bg = bg } },
                command  = { a = { fg = dark, bg = "#957FB8", gui = "bold" }, b = { fg = text, bg = mid }, c = { fg = text, bg = bg } },
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
                                added    = { fg = "#98BB6C" },
                                modified = { fg = "#E6C384" },
                                removed  = { fg = "#E46876" },
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
