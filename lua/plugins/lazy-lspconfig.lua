-- nvim-lspconfig

-- Note: BufReadPre triggers before the STARTUP event, so it's preferable to use the BufReadPost event instead so that other important plugins, like filetype, have a chance to load.

return {
    "neovim/nvim-lspconfig",
    name    = "lspconfig",
    enabled = true,
    lazy    = true,
    event   = {
        "BufReadPost",
        "BufNewFile"
    },
    -- dependencies = {
    --     "hrsh7th/nvim-cmp",
    -- },
    config = function()
		local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
		if not lspconfig_ok then
            vim.notify(vim.inspect(lspconfig), vim.log.levels.ERROR)
			return
		end

		local lsputil_ok, lsputil = pcall(require, "lspconfig.util")
		if not lsputil_ok then
            vim.notify(vim.inspect(lsputil), vim.log.levels.ERROR)
		    return
		end

        -- This probably isn't the ideal way to deal with capabilities. Don't I need to do the whole deep force shenanigans?
        local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

		local on_attach = function(_, bufnr)
            -- vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
            vim.keymap.set("n", "gd", vim.lsp.buf.definition)
        end

        -- Once LSP servers have been installed with Mason, Node, etc.,
        -- they need to be setup here.

        -- luals
        lspconfig.lua_ls.setup({
            filetypes = {"lua"},
            on_attach = on_attach,
            capabilities = capabilities,
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

        lspconfig.ols.setup({
            filetypes = {"odin"},
            on_attach = on_attach,
            capabilities = capabilities,
            default_config = {
                cmd = { "ols" },
                filetypes = { "odin" },
                root_dir = lsputil.root_pattern("ols.json", ".git"),
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
        -- lspconfig.pyright.setup({
        --     filetypes = {"python"},
        --     on_attach = on_attach,
        --     capabilities = capabilities,
        --     settings = {
        --         python = {
        --             analysis = {
        --                 autoSearchPaths = true,
        --                 diagnosticMode = "workspace",
        --                 extraPaths = {"c:/users/christopher/appdata/local/programs/python/python310/lib/site-packages"}, -- This resolves an issue where third party imports can't be resolved because they're not in the root directory of the working file.
        --                 useLibraryCodeForTypes = true,
        --             },
        --         },
        --     },
        -- })

        -- tsserver
        lspconfig.tsserver.setup({
            filetypes = {"javascript", "typescript"},
            on_attach = on_attach,
            capabilities = capabilities,
        })

    end,
}
