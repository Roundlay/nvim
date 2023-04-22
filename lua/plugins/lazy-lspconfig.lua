return {
    "neovim/nvim-lspconfig",
    name = "LSP Config",
    enabled = true,
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
		local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
		if not lspconfig_ok then
			return
		end

		local lsputil_ok, lsputil = pcall(require, "lspconfig.util")
		if not lsputil_ok then
			return
		end

		local lspconfigs_ok, lspconfigs = pcall(require, "lspconfig.configs")
		if not lspconfigs_ok then
			return
		end

		local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
		if not cmp_nvim_lsp_ok then
			return
		end

		local capabilities = cmp_nvim_lsp.default_capabilities()

		local on_attach = function(client, bufnr)
            vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
			local opts = { silent = true, buffer = bufnr }
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        end

        -- LSP Servers

        -- luals

        lspconfig.lua_ls.setup ({
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { 'vim' },
                    },
                },
            },
        })

        -- ols

        if not lspconfigs.ols then
            lspconfigs.ols = {
                default_config = {
                    cmd = { "ols" },
                    filetypes = { "odin" },
                    root_dir = lsputil.root_pattern("ols.json", ".git"),
                    single_file_support = true,
                    settings = {},
                }
            }
        end

        lspconfigs.ols.setup{
            on_attach = on_attach,
            capabilities = capabilities,
        }

        -- LSP setup template

        -- Setting up bash server
        -- lspconfigs.bashls.setup({
        --   on_attach = on_attach,
        --   capabilities = capabilities,
        -- })
    end,
}
