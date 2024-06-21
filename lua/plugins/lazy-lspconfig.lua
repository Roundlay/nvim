-- nvim-lspconfig

-- Incomming dependencies: N/A
-- Outgoing dependencies: mason-lspconfig.nvim

return {
    "neovim/nvim-lspconfig",
    -- name = "lspconfig",
    enabled = true,
    lazy = true,
    event = {
        "BufReadPre",
    },
    cmd = {
        "LspInfo", "LspInstall",
    },
    dependencies = {
        -- Depedencies to be loaded before nvim-lspconfig.
        -- We need to make sure that `mason` is loaded in the following order:
        -- `mason` -> `mason-lspconfig.nvim` -> `nvim-lspconfig`
        -- We call `mason-lspconfig` here, which in turn calls `mason`.
        -- In effect, before `nvim-lspconfig` is loaded, `mason` and
        -- `mason-lspconfig` are loaded in that order.
        "williamboman/mason.nvim",
        { "williamboman/mason-lspconfig.nvim", module = "mason" },
        -- "hrsh7th/nvim-cmp",
    },
    opts = {
        diagnostics = {
            enabled = true,
            underline = true,
            update_in_insert = true,
            virtual_text = {
                spacing = 4,
                source = "always",
                prefix = "·",
            },
        },
    },
    config = function(_, opts)
		local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
		if not lspconfig_ok then
            vim.notify(vim.inspect(lspconfig), vim.log.levels.ERROR)
			return
		end

        -- We use `vim.tbl_deep_extend` to merge the defaults lspconfig
        -- provides with the capabilities `nvim-cmp` adds.
        -- This will cause `cmp_nvim_lsp` to be loaded right away,
        -- overriding any lazy-loading defined in `lazy-cmp-nvim-lsp.lua`.

        local cmp_ok, cmp = pcall(require, "cmp_nvim_lsp")
		if not cmp_ok then
            vim.notify(vim.inspect(cmp), vim.log.levels.ERROR)
			return
		end

        local capabilities = vim.lsp.protocol.make_client_capabilities()

        lspconfig.util.default_config.capabilities = vim.tbl_deep_extend("force", lspconfig.util.default_config.capabilities, cmp.default_capabilities(capabilities))

        local bufnr = vim.api.nvim_get_current_buf()
        local client = vim.lsp.get_active_clients()

		on_attach = function(_, bufnr)
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
            vim.keymap.set("n", "gd", vim.lsp.buf.definition)
        end

        -- Once LSP servers have been installed manually, with Mason, etc.,
        -- they need to be set up here.

        -- luals
        lspconfig.lua_ls.setup({
            filetypes = {"lua"},
            on_attach = on_attach,
            capabilities = capabilities,
            default_config = {
                cmd = { vim.fn.exepath("lua-language-server") },
            },
            settings = {
                Lua = {
                    diagnostics = vim.tbl_extend('force', opts.diagnostics, {
                        globals = {"vim"},
                    }),
                    workspace = {
                        library = vim.api.nvim_get_runtime_file("", true),
                        checkThirdParty = false,
                    },
                    telemetry = {
                        enable = false,
                    },
                },
            },
        })

        -- ols
        lspconfig.ols.setup({
            filetypes = {"odin"},
            on_attach = on_attach,
            capabilities = capabilities,
            default_config = {
                cmd = {"ols"},
                filetypes = {"odin"},
                root_dir = lspconfig.util.root_pattern("ols.json", ".git"),
                single_file_support = true,
            },
        })

        -- vim-language-server
        lspconfig.vimls.setup({
            on_attach = on_attach,
            capabilities = capabilities,
            init_options = {
                diagnostics = {
                    opts.diagnostic,
                },
            },
        })

        -- pyright
        lspconfig.pyright.setup({
            filetypes = {"python"},
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
                python = {
                    analysis = {
                        autoSearchPaths = true,
                        diagnosticMode = "workspace",
                        extraPaths = {"c:/users/christopher/appdata/local/programs/python/python310/lib/site-packages"}, -- This resolves an issue where third party imports can't be resolved because they're not in the root directory of the working file.
                        useLibraryCodeForTypes = true,
                    },
                },
            },
        })

        --html-lsp
        lspconfig.html.setup({
            filetypes = {"html"},
            on_attach = on_attach,
            capabilities = capabilities,
        })

        --css-lsp
        lspconfig.cssls.setup({
            filetypes = {"css"},
            on_attach = on_attach,
            capabilities = capabilities,
        })

        -- marksman
        -- lspconfig.marksman.setup({
        --     filetypes = {"markdown"},
        --     on_attach = on_attach,
        --     capabilities = capabilities,
        -- })

        -- tsserver
        -- lspconfig.tsserver.setup({
        --     filetypes = {"javascript", "typescript"},
        --     on_attach = on_attach,
        --     capabilities = capabilities,
        -- })

    end,
}
