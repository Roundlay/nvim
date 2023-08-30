-- nvim-lspconfig

-- Incomming dependencies: N/A
-- Outgoing dependencies: mason-lspconfig.nvim

return {
    "neovim/nvim-lspconfig",
    -- name = "lspconfig",
    enabled = true,
    lazy = true,
    event = {
        "BufReadPost",
        "InsertEnter",
        "CmdlineEnter",
    },
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/nvim-cmp",
    },
    config = function()
		local lspconfig_ok, lspconfig = pcall(require, "lspconfig")

		if not lspconfig_ok then
            vim.notify(vim.inspect(lspconfig), vim.log.levels.ERROR)
			return
		end

        -- We use `vim.tbl_deep_extend` to merge the defaults lspconfig
        -- provides with the capabilities `nvim-cmp` adds.
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        lspconfig.util.default_config.capabilities = vim.tbl_deep_extend(
            "force",
            lspconfig.util.default_config.capabilities,
            -- This will cause `cmp_nvim_lsp` to be loaded right away,
            -- overriding any lazy-loading defined in `lazy-cmp-nvim-lsp.lua`.
            require("cmp_nvim_lsp").default_capabilities(capabilities)
        )

        local bufnr = vim.api.nvim_get_current_buf()
		local on_attach = function(_, bufnr)
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
                    diagnostics = {
                        globals = {"vim"},
                    },
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
                    enable = true,
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

        -- tsserver
        -- lspconfig.tsserver.setup({
        --     filetypes = {"javascript", "typescript"},
        --     on_attach = on_attach,
        --     capabilities = capabilities,
        -- })

    end,
}
