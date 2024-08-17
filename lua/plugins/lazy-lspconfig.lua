return {
    "neovim/nvim-lspconfig",
    enabled = true,
    lazy = "LazyFile",
    event = { "BufReadPre" },
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    config = function()
        local lspconfig = require("lspconfig")
        local cmp_nvim_lsp = require("cmp_nvim_lsp")

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)

        local on_attach = function(_, bufnr)
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = bufnr })
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
        end

        -- LSP Server Configurations

        -- Lua
        lspconfig.lua_ls.setup({
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { "vim" },
                    },
                    workspace = {
                        library = vim.api.nvim_get_runtime_file("", true),
                        checkThirdParty = false,
                    },
                    telemetry = {
                        enable = false,
                    },
                    type = {
                        castNumberToInteger = true,
                    },
                    window = {
                        progressBar = false,
                        statusbar = false,
                    },
                },
            },
        })

        -- Pyright
        lspconfig.pyright.setup({
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
                python = {
                    analysis = {
                        autoSearchPaths = true,
                        diagnosticMode = "workspace",
                        extraPaths = { "c:/users/christopher/appdata/local/programs/python/python310/lib/site-packages" },
                        useLibraryCodeForTypes = true,
                    },
                },
            },
        })

        -- Odin
        lspconfig.ols.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })

        -- VimL
        lspconfig.vimls.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })

        -- HTML
        lspconfig.html.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })

        -- CSS
        lspconfig.cssls.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })

        -- TypeScript
        lspconfig.tsserver.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })

        -- Clangd
        lspconfig.clangd.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })

        -- Omnisharp
        lspconfig.omnisharp.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })
    end,
}
