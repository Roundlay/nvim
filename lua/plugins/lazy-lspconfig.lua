-- nvim-lspconfig

return {
    "neovim/nvim-lspconfig",
    enabled = true,

    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },

    config = function()
        local lspconfig = require("lspconfig")
        local util      = require("lspconfig.util")

        local blink_ok, blink = pcall(require, 'blink.cmp')
        if not blink_ok then
            vim.notify("Failed to load blink.cmp", vim.log.levels.ERROR)
            return
        end

        -- Start with default LSP capabilities
        local capabilities = vim.lsp.protocol.make_client_capabilities()

        -- Enhance with blink.cmp's completion capabilities
        capabilities = vim.tbl_deep_extend('force', capabilities, blink.get_lsp_capabilities() or {})

        util.default_config = vim.tbl_deep_extend( "force", util.default_config, { flags = { debounce_text_changes = 1 } })

        -- Set up buffer-local keymaps after LSP attaches
        vim.keymap.set("n", "gd", function()
            local bufnr = vim.api.nvim_get_current_buf()
            local clients = vim.lsp.get_clients({bufnr = bufnr})
            local enc = (clients[1] or {}).offset_encoding or "utf-16"
            local params = vim.lsp.util.make_position_params(0, enc)

            vim.lsp.buf_request(bufnr, "textDocument/definition", params, function(err, result)
                if err then
                    vim.api.nvim_err_writeln("LSP definition error: " .. err.message)
                    return
                end

                if not result or vim.tbl_isempty(result) then
                    print("No definition found")
                    return
                end

                local def = result[1] or result
                local uri = def.uri or def.targetUri
                local path = vim.uri_to_fname(uri)
                local win_id = vim.fn.bufwinid(path)

                if win_id == -1 then
                    vim.cmd("vsplit " .. vim.fn.fnameescape(path))
                else
                    vim.fn.win_gotoid(win_id)
                end

                vim.lsp.util.show_document(def, enc, {true, true})
            end)
        end, {buffer = true})

        local base_config = {
            on_attach    = on_attach,
            capabilities = capabilities,
        }

        local servers = {
            vimls = {},
            yamlls = {},
            marksman = {},
            cssls = {},
            html = {},
            jsonls = {},

            clangd = {
                cmd = { "clangd", "--background-index", "--clang-tidy", "--inlay-hints", "--function-arg-placeholders" }, -- UPDATED: Added --function-arg-placeholders
                settings = {
                    clangd = {
                        semanticHighlighting = true,
                        inactiveRegions = {
                            opacity = 0.0,
                            useBackgroundHighlight = false,
                        },
                        InlayHints = {
                            Enabled = true,
                            Designators = true,
                            ParameterNames = true,
                            DeducedTypes = true,
                        },
                    },
                },
            },

            lua_ls = {
                on_init = function(client)
                    local wf = client.workspace_folders
                    local first = wf and wf[1] and wf[1].name or nil
                    if first and (vim.uv.fs_stat(first .. '/.luarc.json') or
                        vim.uv.fs_stat(first .. '/.luarc.jsonc')) then
                        return
                    end

                    client.config.settings.Lua = vim.tbl_deep_extend('force',
                    client.config.settings.Lua or {}, {
                        runtime = { version = 'LuaJIT' },
                        workspace = {
                            checkThirdParty = false,
                            library = {
                                vim.env.VIMRUNTIME,
                                vim.fn.stdpath('config'),
                            },
                        },
                        diagnostics = {
                            globals = { 'vim' },
                        },
                        telemetry = { enable = false },
                    })
                    client.notify('workspace/didChangeConfiguration', { settings = client.config.settings })
                end,
                settings = {
                    Lua = {},
                },
            },

            ols = {
                cmd = { "C:\\Users\\Christopher\\AppData\\Local\\nvim-data\\mason\\packages\\ols\\ols-x86_64-pc-windows-msvc.exe" },
                init_options = {
                    checker_args = "-strict-style",
                    collections = {
                        { name = "shared", path = "C:\\Users\\Christopher\\scoop\\apps\\odin\\current\\shared" },
                        { name = "vendor", path = "C:\\Users\\Christopher\\scoop\\apps\\odin\\current\\vendor" },
                        { name = "core",   path = "C:\\Users\\Christopher\\scoop\\apps\\odin\\current\\core"   },
                    },
                },
            },

            pyright = {
                root_dir = function(fname)
                    return util.root_pattern("pyproject.toml", "setup.py", ".git")(fname)
                    or util.path.dirname(fname)
                end,
                settings = {
                    python = {
                        analysis = {
                            autoSearchPaths       = true,
                            diagnosticMode        = "openFilesOnly",
                            extraPaths            = { "C:\\Users\\Christopher\\AppData\\Local\\Programs\\python\\python310\\lib\\site-packages" },
                            useLibraryCodeForTypes = true,
                            skipLibCheck          = true,
                        },
                    },
                },
            },
        }

        -- Setup each server by merging base + overrides
        for name, override in pairs(servers) do
            lspconfig[name].setup(vim.tbl_deep_extend("force", base_config, override))
        end
    end,
}
