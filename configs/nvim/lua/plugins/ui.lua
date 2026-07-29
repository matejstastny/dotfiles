local ellie = {
    base    = "#11111b",
    surface = "#181825",
    overlay = "#25253a",
    muted   = "#3d3d5c",
    purple  = "#7878c8", -- accent
    rose    = "#c47ab8", -- dusty rose
    text    = "#dce0f4",
    dim     = "#9898c0",
    bright  = "#f0f0ff",
}

return {
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
                -- Remap the whole mocha palette onto the Ellie ramp. Neutrals become
                -- the midnight purples; accents lean purple/rose while keeping the
                -- diagnostic colours (red/yellow/green/blue) distinguishable.
                color_overrides = {
                    mocha = {
                        rosewater = "#f0d4e4",
                        flamingo  = "#dba8c0",
                        pink      = ellie.rose,
                        mauve     = ellie.purple,
                        red       = "#e06a8a",
                        maroon    = "#d48aa4",
                        peach     = "#d69a7a",
                        yellow    = "#d8bd8a",
                        green     = "#8fbf9f",
                        teal      = "#7fbfb0",
                        sky       = "#8fb5d6",
                        sapphire  = "#87a3d6",
                        blue      = "#9a97d6",
                        lavender  = "#b39ee0",
                        text      = ellie.text,
                        subtext1  = "#cbbce4",
                        subtext0  = ellie.dim,
                        overlay2  = "#8574a0",
                        overlay1  = "#6d5d88",
                        overlay0  = "#544666",
                        surface2  = ellie.muted,
                        surface1  = "#2f2f48",
                        surface0  = ellie.overlay,
                        base      = ellie.base,
                        mantle    = ellie.surface,
                        crust     = "#07050d",
                    },
                },
                integrations = {
                    treesitter       = true,
                    telescope        = { enabled = true },
                    lualine          = true,
                    gitsigns         = true,
                    mason            = true,
                    which_key        = true,
                    blink_cmp        = true,
                    native_lsp       = {
                        enabled = true,
                        underlines = {
                            errors      = { "undercurl" },
                            hints       = { "undercurl" },
                            warnings    = { "undercurl" },
                            information = { "undercurl" },
                        }
                    },
                    indent_blankline = { enabled = true, colored_indent_levels = false },
                    illuminate       = { enabled = true },
                    neotree          = true,
                    snacks           = true,
                },
                highlight_overrides = {
                    mocha = function(c)
                        return {
                            -- Telescope - clear all pane backgrounds for the floating look
                            TelescopeNormal            = { bg = "NONE" },
                            TelescopePromptNormal      = { bg = "NONE" },
                            TelescopeResultsNormal     = { bg = "NONE" },
                            TelescopePreviewNormal     = { bg = "NONE" },
                            TelescopeBorder            = { bg = "NONE", fg = c.subtext1 },
                            TelescopePromptBorder      = { bg = "NONE", fg = c.subtext1 },
                            TelescopeResultsBorder     = { bg = "NONE", fg = c.subtext1 },
                            TelescopePreviewBorder     = { bg = "NONE", fg = c.subtext1 },
                            TelescopePromptTitle       = { bg = "NONE", fg = c.mauve },
                            TelescopeResultsTitle      = { bg = "NONE", fg = c.mauve },
                            TelescopePreviewTitle      = { bg = "NONE", fg = c.mauve },
                            TelescopeSelection         = { bg = c.surface0 },
                            TelescopeSelectionCaret    = { fg = c.mauve },
                            TelescopeMatching          = { fg = c.pink, style = { "bold" } },
                            -- Floating windows (hover, signature, blink menu)
                            NormalFloat                = { bg = "NONE" },
                            FloatBorder                = { bg = "NONE", fg = c.overlay2 },
                            -- Cursor line / column subtle
                            CursorLine                 = { bg = c.mantle },
                            -- Diagnostics virtual text a touch dimmer
                            DiagnosticVirtualTextError = { fg = c.red, bg = "NONE" },
                            DiagnosticVirtualTextWarn  = { fg = c.yellow, bg = "NONE" },
                            DiagnosticVirtualTextHint  = { fg = c.teal, bg = "NONE" },
                            DiagnosticVirtualTextInfo  = { fg = c.sky, bg = "NONE" },
                        }
                    end,
                },
            })
            vim.cmd("colorscheme catppuccin-mocha")
            -- Clear any remaining opaque highlights after the colorscheme loads
            for _, g in ipairs({ "WinBar", "WinBarNC", "NeoTreeNormal", "NeoTreeNormalNC" }) do
                vim.api.nvim_set_hl(0, g, { bg = "NONE" })
            end
        end,
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local c = require("catppuccin.palettes").get_palette("mocha")

            -- transparent middle sections, coloured mode pill, star-accented
            local theme = {
                normal   = { a = { fg = ellie.base, bg = c.mauve, gui = "bold" }, b = { fg = c.text, bg = "NONE" }, c = { fg = c.subtext0, bg = "NONE" } },
                insert   = { a = { fg = ellie.base, bg = c.green, gui = "bold" }, b = { fg = c.text, bg = "NONE" }, c = { fg = c.subtext0, bg = "NONE" } },
                visual   = { a = { fg = ellie.base, bg = c.flamingo, gui = "bold" }, b = { fg = c.text, bg = "NONE" }, c = { fg = c.subtext0, bg = "NONE" } },
                replace  = { a = { fg = ellie.base, bg = c.pink, gui = "bold" }, b = { fg = c.text, bg = "NONE" }, c = { fg = c.subtext0, bg = "NONE" } },
                command  = { a = { fg = ellie.base, bg = c.peach, gui = "bold" }, b = { fg = c.text, bg = "NONE" }, c = { fg = c.subtext0, bg = "NONE" } },
                inactive = { a = { fg = c.overlay0, bg = "NONE" }, b = { fg = c.overlay0, bg = "NONE" }, c = { fg = c.overlay0, bg = "NONE" } },
            }

            -- Show the active LSP client(s) in the statusline
            local function lsp_names()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients == 0 then return "" end
                local names = {}
                for _, client in ipairs(clients) do
                    if client.name ~= "null-ls" then names[#names + 1] = client.name end
                end
                return " " .. table.concat(names, ", ")
            end

            require("lualine").setup({
                options = {
                    theme                = theme,
                    component_separators = { left = "·", right = "·" },
                    section_separators   = { left = "", right = "" },
                    globalstatus         = true,
                    disabled_filetypes   = { statusline = { "dashboard", "snacks_dashboard" } },
                },
                sections = {
                    lualine_a = { { "mode", fmt = function(s) return s:sub(1, 1) end } },
                    lualine_b = {
                        { "branch", icon = "" },
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
                        { "filename", path = 1, symbols = { modified = " ✦", readonly = " ", unnamed = "~" } },
                    },
                    lualine_x = {
                        {
                            "diagnostics",
                            sources = { "nvim_lsp" },
                            symbols = { error = " ", warn = " ", info = " ", hint = " " },
                        },
                        { lsp_names,  color = { fg = c.mauve } },
                        { "filetype", colored = true,          icon_only = false },
                    },
                    lualine_y = {},
                    lualine_z = {
                        { "location", fmt = function(s) return "Ln " .. s:gsub(":", ", Col ") end },
                        { "progress" },
                    },
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { { "filename", path = 1 } },
                    lualine_x = { "location" },
                    lualine_y = {},
                    lualine_z = {},
                },
                extensions = { "neo-tree", "lazy", "mason" },
            })
        end,
    },

    -- Transparent
    {
        "xiyaowong/transparent.nvim",
        lazy = false,
        opts = {
            extra_groups = { "NormalFloat" },
        },
    }
}
