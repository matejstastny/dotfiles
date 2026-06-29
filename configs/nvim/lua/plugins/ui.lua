return {
    -- Catppuccin Mocha Noir — base shifted to crust for deeper darkness
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                transparent_background = true,
                dim_inactive = { enabled = true, shade = "dark", percentage = 0.12 },
                styles = {
                    comments  = { "italic" },
                    keywords  = {},
                    functions = { "italic" },
                },
                color_overrides = {
                    mocha = {
                        -- Noir shift: use crust as base, sink everything darker
                        base   = "#11111b",
                        mantle = "#0d0d17",
                        crust  = "#090910",
                    },
                },
                integrations = {
                    treesitter        = true,
                    telescope         = { enabled = true },
                    lualine           = true,
                    gitsigns          = true,
                    mason             = true,
                    which_key         = true,
                    indent_blankline  = { enabled = true, colored_indent_levels = false },
                    illuminate        = { enabled = true },
                    neotree           = true,
                },
                highlight_overrides = {
                    mocha = function(c)
                        return {
                            -- Telescope — clear all pane backgrounds
                            TelescopeNormal          = { bg = "NONE" },
                            TelescopePromptNormal    = { bg = "NONE" },
                            TelescopeResultsNormal   = { bg = "NONE" },
                            TelescopePreviewNormal   = { bg = "NONE" },
                            TelescopeBorder          = { bg = "NONE", fg = c.surface1 },
                            TelescopePromptBorder    = { bg = "NONE", fg = c.surface1 },
                            TelescopeResultsBorder   = { bg = "NONE", fg = c.surface1 },
                            TelescopePreviewBorder   = { bg = "NONE", fg = c.surface1 },
                            TelescopePromptTitle     = { bg = "NONE", fg = c.mauve },
                            TelescopeResultsTitle    = { bg = "NONE", fg = c.mauve },
                            TelescopePreviewTitle    = { bg = "NONE", fg = c.mauve },
                            TelescopeSelection       = { bg = c.surface0 },
                            TelescopeSelectionCaret  = { fg = c.mauve },
                            TelescopeMatching        = { fg = c.pink, style = { "bold" } },
                        }
                    end,
                },
            })
            vim.cmd("colorscheme catppuccin-mocha")
            -- Clear any remaining opaque highlights after colorscheme loads
            for _, g in ipairs({ "WinBar", "WinBarNC", "NeoTreeNormal", "NeoTreeNormalNC" }) do
                vim.api.nvim_set_hl(0, g, { bg = "NONE" })
            end
        end,
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        lazy = false,
        config = function()
            local c = require("catppuccin.palettes").get_palette("mocha")
            local noir = "#11111b"

            local theme = {
                normal   = { a = { fg = noir, bg = c.mauve,    gui = "bold" }, b = { fg = c.text, bg = "NONE" }, c = { fg = c.text, bg = "NONE" } },
                insert   = { a = { fg = noir, bg = c.green,    gui = "bold" }, b = { fg = c.text, bg = "NONE" }, c = { fg = c.text, bg = "NONE" } },
                visual   = { a = { fg = noir, bg = c.flamingo, gui = "bold" }, b = { fg = c.text, bg = "NONE" }, c = { fg = c.text, bg = "NONE" } },
                replace  = { a = { fg = noir, bg = c.pink,     gui = "bold" }, b = { fg = c.text, bg = "NONE" }, c = { fg = c.text, bg = "NONE" } },
                command  = { a = { fg = noir, bg = c.peach,    gui = "bold" }, b = { fg = c.text, bg = "NONE" }, c = { fg = c.text, bg = "NONE" } },
                inactive = { a = { fg = c.overlay0, bg = "NONE" }, b = { fg = c.overlay0, bg = "NONE" }, c = { fg = c.overlay0, bg = "NONE" } },
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
                                added    = { fg = c.green },
                                modified = { fg = c.yellow },
                                removed  = { fg = c.maroon },
                            },
                        },
                    },
                    lualine_c = {
                        { "filename", symbols = { modified = " ✦", readonly = " ", unnamed = "~" } },
                    },
                    lualine_x = {
                        {
                            "diagnostics",
                            sources  = { "nvim_lsp" },
                            sections = { "error", "warn" },
                            symbols  = { error = "E:", warn = "W:" },
                        },
                    },
                    lualine_y = { "filetype" },
                    lualine_z = {
                        { "location", fmt = function(s) return "Ln " .. s:gsub(":", ", Col ") end },
                    },
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
