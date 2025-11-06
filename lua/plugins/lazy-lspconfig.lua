-- nvim-lspconfig

return {
    "neovim/nvim-lspconfig",
    enabled = true,
    lazy = true,
    ft = {
        "c",
        "cpp",
        "objc",
        "objcpp",
        "cc",
        "cxx",
        "h",
        "hpp",
        "lua",
        "python",
        "swift",
        "odin",
        "json",
        "yaml",
        "yml",
        "markdown",
        "md",
        "vim",
        "css",
        "html",
    },
    cmd = { "LspInfo", "LspLog", "LspRestart", "LspStop" },

    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },

    config = function()
        local util      = require("lspconfig.util")

        local blink_caps = {}
        local blink_ok, blink = pcall(require, 'blink.cmp')
        if blink_ok and type(blink.get_lsp_capabilities) == "function" then
            blink_caps = blink.get_lsp_capabilities() or {}
        end

        if not (vim.lsp and vim.lsp.config and vim.lsp.enable) then
            vim.notify("vim.lsp.config API is unavailable (requires Neovim 0.11+)", vim.log.levels.ERROR)
            return
        end

        -- Start with default LSP capabilities and opt out of dynamic file watching by default
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities.workspace = capabilities.workspace or {}
        capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = false }

        -- Enhance with blink.cmp's completion capabilities
        capabilities = vim.tbl_deep_extend('force', capabilities, blink_caps)

        -- Swift LSP setup
        local swift_root = util.root_pattern("Package.swift", ".git")
        local os_info = vim.uv.os_uname()
        local is_windows = os_info and os_info.sysname:match("Windows") ~= nil
        local function norm(path)
            return vim.fs.normalize(path)
        end

        ---------------------------------------------------------------------
        -- Adapter: old synchronous root resolvers -> new async root_dir API.
        ---------------------------------------------------------------------
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

        ---------------------------------------------------------------------
        -- Thin wrapper around the default definition handler that keeps
        -- notifications consistent while deferring window selection to
        -- Neovim's built-in jump logic.
        ---------------------------------------------------------------------
        local function goto_definition()
            local bufnr = vim.api.nvim_get_current_buf()
            local clients = vim.lsp.get_clients({ bufnr = bufnr })
            local enc = (clients[1] or {}).offset_encoding

            local params = vim.lsp.util.make_position_params(0, enc)
            vim.lsp.buf_request(bufnr, "textDocument/definition", params, function(err, result)
                if err then
                    vim.notify(("LSP definition error: %s"):format(err.message), vim.log.levels.ERROR)
                    return
                end
                if not result or vim.tbl_isempty(result) then
                    vim.notify("No definition found", vim.log.levels.INFO)
                    return
                end

                local loc = vim.tbl_islist(result) and result[1] or result
                vim.lsp.util.jump_to_location(loc, enc)
            end)
        end

        -- Buffer-local keymaps are attached via `on_attach` so that they are
        -- available for *every* LSP-enabled buffer instead of only the buffer
        -- that happened to be current during start-up.
        local function on_attach(_, bufnr)
            vim.keymap.set("n", "gd", goto_definition, { buffer = bufnr, desc = "Go to definition" })
        end

        local base_config = {
            on_attach = on_attach,
            capabilities = capabilities,
            flags = {
                debounce_text_changes = 150,
            },
        }

        local servers = {
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

            sourcekit = {
                filetypes = { "swift" },
                root_dir = adapt_root_dir(function(fname)
                    return swift_root(fname) or util.path.dirname(fname)
                end),
                single_file_support = true,
                capabilities = {
                    workspace = {
                        didChangeWatchedFiles = {
                            dynamicRegistration = true,
                        },
                    },
                },
            },

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

        -- Setup each server by merging base + overrides
        for name, override in pairs(servers) do
            local merged = vim.tbl_deep_extend("force", {}, base_config, override)
            if override.capabilities then
                merged.capabilities = vim.tbl_deep_extend('force', {}, base_config.capabilities, override.capabilities)
            end
            vim.lsp.config(name, merged)
            configured_servers[#configured_servers + 1] = name
        end

        if #configured_servers > 0 then
            vim.lsp.enable(configured_servers)
        end
    end,
}
