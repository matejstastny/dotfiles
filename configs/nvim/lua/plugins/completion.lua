return {
    -- blink.cmp — fast completion. `version = "*"` pulls the prebuilt Rust
    -- fuzzy matcher so no local `cargo` toolchain is required to build it.
    {
        "saghen/blink.cmp",
        version = "*",
        event = "InsertEnter",
        dependencies = { "rafamadriz/friendly-snippets" },
        opts = {
            -- super-tab: Tab selects/accepts, S-Tab goes back, <CR> falls through
            -- to a real newline unless a menu item is explicitly selected.
            keymap = {
                preset = "super-tab",
                ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
            },
            appearance = { nerd_font_variant = "mono" },
            completion = {
                accept = { auto_brackets = { enabled = true } },
                documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "rounded" } },
                menu = {
                    border = "rounded",
                    draw = { treesitter = { "lsp" } },
                },
                ghost_text = { enabled = true },
            },
            signature = { enabled = true, window = { border = "rounded" } },
            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
            },
            cmdline = {
                sources = { "cmdline" },
                enabled = true,
                completion = { menu = { auto_show = true } },
            },
            fuzzy = { implementation = "prefer_rust_with_warning" },
        },
        opts_extend = { "sources.default" },
    },
}
