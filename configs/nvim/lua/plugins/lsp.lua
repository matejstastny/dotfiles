-- Language servers to run. Keys are lspconfig names; values are extra config
-- merged into the defaults. Mason installs whatever is missing.
local servers = {
    -- Core
    lua_ls = {
        settings = {
            Lua = {
                diagnostics = { globals = { "vim" } },
                workspace   = { checkThirdParty = false },
                telemetry   = { enable = false },
                hint        = { enable = true },
            },
        },
    },
    bashls  = {}, -- uses shellcheck automatically for diagnostics
    pyright = {},
    ruff    = {}, -- python lint + import sorting (formatting via conform)

    -- Web
    ts_ls                  = {},
    html                   = {},
    cssls                  = {},
    tailwindcss            = {},
    emmet_language_server  = {},

    -- Docs / config
    jsonls   = {},
    yamlls   = {},
    taplo    = {},
    marksman = {},

    -- Systems
    rust_analyzer = {}, -- NOTE: needs a working `cargo`/rustup for real projects
    gopls         = {},
    -- clangd has no aarch64 Mason build; use the system binary (clang-tools-extra).
    clangd        = { mason = false },
}

return {
    -- Mason: manages LSP/formatter/linter binaries
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        opts = { ui = { border = "rounded" } },
    },

    -- Auto-install formatters & linters that aren't language servers
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            ensure_installed = {
                "stylua",
                "shfmt",
                "shellcheck",
                "prettierd",
                "clang-format",
                "goimports",
            },
            run_on_start = true,
        },
    },

    -- Formatting on save via conform.nvim
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>cf",
                function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
                mode = { "n", "v" },
                desc = "Format buffer",
            },
        },
        opts = {
            formatters_by_ft = {
                lua              = { "stylua" },
                python           = { "ruff_organize_imports", "ruff_format" },
                sh               = { "shfmt" },
                bash             = { "shfmt" },
                javascript       = { "prettierd", "prettier", stop_after_first = true },
                typescript       = { "prettierd", "prettier", stop_after_first = true },
                javascriptreact  = { "prettierd", "prettier", stop_after_first = true },
                typescriptreact  = { "prettierd", "prettier", stop_after_first = true },
                html             = { "prettierd", "prettier", stop_after_first = true },
                css              = { "prettierd", "prettier", stop_after_first = true },
                json             = { "prettierd", "prettier", stop_after_first = true },
                jsonc            = { "prettierd", "prettier", stop_after_first = true },
                yaml             = { "prettierd", "prettier", stop_after_first = true },
                markdown         = { "prettierd", "prettier", stop_after_first = true },
                rust             = { "rustfmt" },
                go               = { "goimports", "gofmt" },
                c                = { "clang-format" },
                cpp              = { "clang-format" },
                toml             = { "taplo" },
            },
            format_on_save = function(bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                return { timeout_ms = 2000, lsp_format = "fallback" }
            end,
        },
        init = function()
            vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
            vim.api.nvim_create_user_command("FormatDisable", function(args)
                if args.bang then
                    vim.b.disable_autoformat = true
                else
                    vim.g.disable_autoformat = true
                end
            end, { bang = true, desc = "Disable format-on-save (! = current buffer only)" })
            vim.api.nvim_create_user_command("FormatEnable", function()
                vim.b.disable_autoformat = false
                vim.g.disable_autoformat = false
            end, { desc = "Re-enable format-on-save" })
        end,
    },

    -- LSP core
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "saghen/blink.cmp",
        },
        config = function()
            -- Pretty diagnostics
            vim.diagnostic.config({
                virtual_text = { prefix = "●", spacing = 2 },
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = " ",
                        [vim.diagnostic.severity.WARN]  = " ",
                        [vim.diagnostic.severity.HINT]  = " ",
                        [vim.diagnostic.severity.INFO]  = " ",
                    },
                },
                underline        = true,
                update_in_insert = false,
                severity_sort    = true,
                float            = { border = "rounded", source = true },
            })

            -- Keymaps applied when any server attaches to a buffer
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = args.buf, desc = "LSP: " .. desc })
                    end
                    local tb = require("telescope.builtin")
                    map("K",  vim.lsp.buf.hover, "Hover")
                    map("gd", tb.lsp_definitions, "Definitions")
                    map("gr", tb.lsp_references, "References")
                    map("gi", tb.lsp_implementations, "Implementations")
                    map("gy", tb.lsp_type_definitions, "Type definitions")
                    map("gD", vim.lsp.buf.declaration, "Declaration")
                    map("<leader>rn", vim.lsp.buf.rename, "Rename")
                    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
                    map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
                    map("<leader>cs", tb.lsp_document_symbols, "Document symbols")

                    -- Inlay hints toggle (nvim 0.10+)
                    if vim.lsp.inlay_hint then
                        map("<leader>ch", function()
                            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
                        end, "Toggle inlay hints")
                    end
                end,
            })

            -- Completion capabilities from blink.cmp
            local capabilities = require("blink.cmp").get_lsp_capabilities()

            -- Register every server's config and collect the ones Mason should
            -- manage (skip those flagged `mason = false`, e.g. system clangd).
            local mason_servers = {}
            for name, cfg in pairs(servers) do
                local via_mason = cfg.mason ~= false
                cfg.mason = nil
                cfg.capabilities = capabilities
                vim.lsp.config(name, cfg)
                if via_mason then
                    mason_servers[#mason_servers + 1] = name
                end
            end

            -- Let Mason install its servers; we enable everything ourselves so
            -- non-Mason servers (system clangd) start too.
            require("mason-lspconfig").setup({
                ensure_installed = mason_servers,
                automatic_enable = false,
            })
            vim.lsp.enable(vim.tbl_keys(servers))
        end,
    },
}
