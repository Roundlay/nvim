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
            vim.keymap.set("n", "gs", vim.lsp.buf.declaration, { buffer = bufnr })
            
            -- Modified keybinding for definition in vertical split
            vim.keymap.set("n", "gd", function()
                -- Get the definition location
                local params = vim.lsp.util.make_position_params()
                vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result, ctx)
                    if err then
                        vim.api.nvim_err_writeln('Error getting definition: ' .. err.message)
                        return
                    end
                    
                    if not result or vim.tbl_isempty(result) then
                        print("No definition found")
                        return
                    end
                    
                    -- Handle both single and multiple definition results
                    local definition = result[1] and result[1] or result
                    
                    if not definition.uri and not definition.targetUri then
                        print("Definition location not found")
                        return
                    end
                    
                    local definition_uri = definition.uri or definition.targetUri
                    local definition_path = vim.uri_to_fname(definition_uri)
                    
                    -- Check if the file is already open in a window
                    local win_id = vim.fn.bufwinid(definition_path)
                    
                    if win_id == -1 then
                        -- File is not open, create a new vertical split
                        vim.cmd("vsplit " .. vim.fn.fnameescape(definition_path))
                    else
                        -- File is already open, just focus that window
                        vim.fn.win_gotoid(win_id)
                    end
                    
                    -- Jump to the specific location within the file
                    vim.lsp.util.jump_to_location(definition, "utf-8")
                end)
            end, { buffer = bufnr })
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
        lspconfig.ts_ls.setup({
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
