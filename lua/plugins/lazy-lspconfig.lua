-- nvim-lspconfig

local lsp_servers = require("lsp.servers")

return {
    "neovim/nvim-lspconfig",
    enabled = true,
    lazy = true,
    ft = lsp_servers.filetypes,
    cmd = {
        "LspInfo",
        "LspLog",
        "LspRestart",
        "LspStop"
    },
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim"
    },
    config = function()
        local util = require("lspconfig.util")

        local islist = vim.islist or vim.tbl_islist

        if not (vim.lsp and vim.lsp.config and vim.lsp.enable) then
            vim.notify("vim.lsp.config API is unavailable (requires Neovim 0.11+)", vim.log.levels.ERROR)
            return
        end

        local function get_blink_capabilities()
            local ok, blink = pcall(require, "blink.cmp")
            if not ok then
                ok, blink = pcall(require, "blink-cmp")
            end
            if ok and type(blink.get_lsp_capabilities) == "function" then
                return blink.get_lsp_capabilities() or {}
            end
            return {}
        end

        local function build_capabilities()
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities.workspace = capabilities.workspace or {}
            -- Avoid dynamic file watching overhead unless a server explicitly opts in.
            capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = false }
            return vim.tbl_deep_extend("force", capabilities, get_blink_capabilities())
        end

        local os_info = vim.uv.os_uname()
        local is_windows = os_info and os_info.sysname:match("Windows") ~= nil
        local function norm(path)
            return vim.fs.normalize(path)
        end

        -- Adapter: old synchronous root resolvers -> new async root_dir API.
        local function adapt_root_dir(resolver)
            return function(bufnr, on_dir)
                local fname = vim.api.nvim_buf_get_name(bufnr)
                if not fname or fname == '' then
                    return
                end

                local root = resolver(fname)
                if root and root ~= '' then
                    on_dir(root)
                end
            end
        end

        -- Go to definition in a reusable vertical split. The first invocation opens a split anchored to the source window; subsequent calls re-use it per tabpage and only replace the buffer location inside that window.
        local definition_windows = {}

        local function ensure_definition_window(source_win)
            if not (source_win and vim.api.nvim_win_is_valid(source_win)) then
                source_win = vim.api.nvim_get_current_win()
            end

            local tabpage = vim.api.nvim_win_get_tabpage(source_win)
            local win = definition_windows[tabpage]

            if win and vim.api.nvim_win_is_valid(win) then
                return win
            end

            vim.api.nvim_win_call(source_win, function()
                vim.cmd("vsplit")
                win = vim.api.nvim_get_current_win()
            end)

            definition_windows[tabpage] = win
            return win
        end

        local function first_location(result)
            if not result or vim.tbl_isempty(result) then
                return nil
            end
            if result.uri or result.targetUri then
                return result
            end
            if islist(result) then
                return result[1]
            end
            return nil
        end

        local function goto_definition()
            local source_buf = vim.api.nvim_get_current_buf()
            local source_win = vim.api.nvim_get_current_win()
            local clients = vim.lsp.get_clients({ bufnr = source_buf })

            if #clients == 0 then
                vim.notify("No LSP clients attached for definitions", vim.log.levels.WARN)
                return
            end

            local pending = #clients
            local jumped = false
            local last_err = nil
            local supporting = 0

            local function maybe_report()
                if jumped or pending > 0 then
                    return
                end
                if supporting == 0 then
                    vim.notify("Attached LSP clients do not support textDocument/definition", vim.log.levels.WARN)
                    return
                end
                if last_err then
                    vim.notify(("LSP definition error: %s"):format(last_err.message or last_err), vim.log.levels.ERROR)
                else
                    vim.notify("No definition found", vim.log.levels.INFO)
                end
            end

            local function handle_response(err, result, ctx)
                if jumped then
                    return
                end

                pending = pending - 1

                if err then
                    last_err = last_err or err
                    return maybe_report()
                end

                local loc = first_location(result)
                if loc then
                    local client = vim.lsp.get_client_by_id(ctx.client_id)
                    local enc = (client and client.offset_encoding) or "utf-16"
                    local win = ensure_definition_window(source_win)
                    if win and vim.api.nvim_win_is_valid(win) then
                        vim.api.nvim_set_current_win(win)
                        vim.lsp.util.jump_to_location(loc, enc)
                        jumped = true
                        return
                    end
                end

                maybe_report()
            end

            for _, client in ipairs(clients) do
                local supports_definition = not client.supports_method or client.supports_method("textDocument/definition")
                if not supports_definition then
                    pending = pending - 1
                else
                    supporting = supporting + 1
                    local enc = client.offset_encoding or "utf-16"
                    local params = vim.lsp.util.make_position_params(source_win, enc)
                    local ok, req_err = client.request("textDocument/definition", params, handle_response, source_buf)
                    if not ok then
                        pending = pending - 1
                        last_err = last_err or { message = req_err }
                    end
                end
            end

            maybe_report()
        end

        -- Buffer-local keymaps are attached via `on_attach` so that they are available for every LSP-enabled buffer instead of only the buffer that happened to be current during start-up.
        local function on_attach(_, bufnr)
            vim.keymap.set("n", "gd", goto_definition, { buffer = bufnr, desc = "Go to definition" })
        end

        local base_config = {
            on_attach = on_attach,
            capabilities = build_capabilities(),
            flags = {
                debounce_text_changes = 150,
            },
        }

        local server_overrides = {
            vimls = {
                filetypes = { "vim" },
            },
            yamlls = {
                filetypes = { "yaml", "yml" },
            },
            marksman = {
                filetypes = { "markdown", "md" },
            },
            cssls = {
                filetypes = { "css" },
            },
            html = {
                filetypes = { "html" },
            },
            jsonls = {
                filetypes = { "json" },
            },

            -- sourcekit = {
            --     filetypes = { "swift" },
            --     root_dir = adapt_root_dir(function(fname)
            --         return swift_root(fname) or util.path.dirname(fname)
            --     end),
            --     single_file_support = true,
            --     capabilities = {
            --         workspace = {
            --             didChangeWatchedFiles = {
            --                 dynamicRegistration = true,
            --             },
            --         },
            --     },
            -- },

            clangd = {
                filetypes = { "c", "cpp", "objc", "objcpp", "cc", "cxx", "h", "hpp" },
                --
                -- NOTE: Upstream clangd >= 20.1 changed several CLI flags:
                --   * `--inlay-hints` is now a no-op (inlay hints are configured via
                --     `InlayHints.*` in the LSP settings instead)
                --   * `--function-arg-placeholders` now requires an explicit boolean
                --     value ("=true"/"=false") and crashes when the value is omitted.
                -- Passing the old flag list therefore terminates the server with
                -- exit-code 1.  Strip the obsolete / breaking flags – we already set
                -- the corresponding features through the `settings` table below.
                --
                cmd = { "clangd", "--background-index", "--clang-tidy" },
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
                filetypes = { "lua" },
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
                filetypes = { "odin" },
                cmd = is_windows and { norm("C:/Users/Christopher/AppData/Local/ols/ols.exe") } or { "ols" },
                init_options = {
                    checker_args = "-strict-style",
                    collections = is_windows and {
                        { name = "shared", path = norm("C:/Users/Christopher/scoop/apps/odin/current/shared") },
                        { name = "vendor", path = norm("C:/Users/Christopher/scoop/apps/odin/current/vendor") },
                        { name = "core",   path = norm("C:/Users/Christopher/scoop/apps/odin/current/core")   },
                    } or nil,
                },
            },

            pyright = {
                filetypes = { "python" },
                root_dir = adapt_root_dir(function(fname)
                    return util.root_pattern("pyproject.toml", "setup.py", "requirements.txt", ".git")(fname)
                        or util.path.dirname(fname)
                end),
                settings = {
                    python = {
                        analysis = {
                            autoSearchPaths        = true,
                            diagnosticMode         = "openFilesOnly",
                            useLibraryCodeForTypes = true,
                            skipLibCheck           = true,
                        },
                    },
                },
            },
        }

        local configured_servers = {}

        local function merge_config(base, override)
            local merged = vim.tbl_deep_extend("force", {}, base, override)
            if override.capabilities then
                merged.capabilities = vim.tbl_deep_extend("force", {}, base.capabilities, override.capabilities)
            end
            return merged
        end

        -- Setup each server by merging base + overrides
        local server_names = lsp_servers.server_names
        for i = 1, #server_names do
            local name = server_names[i]
            local override = server_overrides[name] or {}
            vim.lsp.config(name, merge_config(base_config, override))
            configured_servers[#configured_servers + 1] = name
        end

        if #configured_servers > 0 then
            vim.lsp.enable(configured_servers)
        end
    end,
}
