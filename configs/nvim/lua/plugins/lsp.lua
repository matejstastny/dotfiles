return {
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        config = true,
    },

    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = { "bashls", "pyright", "lua_ls" },
                automatic_installation = true,
            })

            -- Keymaps on attach (nvim 0.11+ style)
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local map = function(keys, func)
                        vim.keymap.set("n", keys, func, { buffer = args.buf })
                    end
                    map("K",          vim.lsp.buf.hover)
                    map("gd",         vim.lsp.buf.definition)
                    map("<leader>rn", vim.lsp.buf.rename)
                end,
            })

            -- lua_ls needs to know about the vim global
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                        workspace   = { checkThirdParty = false },
                        telemetry   = { enable = false },
                    },
                },
            })

            vim.lsp.enable({ "bashls", "pyright", "lua_ls" })
        end,
    },
}
