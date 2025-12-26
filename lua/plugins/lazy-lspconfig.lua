-- nvim-lspconfig

return {
    "neovim/nvim-lspconfig",
    enabled = true,
    lazy = true,
    ft = {
        -- C/C++/Objective-C (clangd)
        "c", "cpp", "objc", "objcpp",
        -- Lua (lua_ls)
        "lua",
        -- Python (pyright)
        "python",
        -- Odin (ols)
        "odin",
        -- Web (html, cssls, jsonls)
        "html", "css", "json", "jsonc",
        -- Vim (vimls)
        "vim",
        -- Markdown (marksman)
        "markdown",
    },
    cmd = {
        "LspInfo",
        "LspLog",
        "LspRestart",
        "LspStop",
    },
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    config = function()
        if not (vim.lsp and vim.lsp.config and vim.lsp.enable) then
            vim.notify("vim.lsp.config API is unavailable (requires Neovim 0.11+)", vim.log.levels.ERROR)
            return
        end

        -- blink.cmp provides LSP capabilities for snippet/completion support.
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

        local function apply_hover_theme()
            if vim.g._vscode_hover_light_applied then
                return
            end
            vim.g._vscode_hover_light_applied = true

            local base_hover = vim.lsp.handlers["textDocument/hover"] or vim.lsp.handlers.hover
            local winhl = table.concat({
                "NormalFloat:VscodeHoverNormal",
                "Normal:VscodeHoverNormal",
                "FloatBorder:VscodeHoverBorder",
                "FloatTitle:VscodeHoverTitle",
            }, ",")

            vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
                config = config or {}
                if config.border == nil then
                    config.border = "single"
                end
                local bufnr, winid = base_hover(err, result, ctx, config)
                if winid and vim.api.nvim_win_is_valid(winid) then
                    local ok = pcall(vim.api.nvim_set_option_value, "winhighlight", winhl, { win = winid })
                    if not ok then
                        pcall(vim.api.nvim_win_set_option, winid, "winhighlight", winhl)
                    end
                end
                return bufnr, winid
            end
        end

        local os_info = vim.uv.os_uname()
        local is_windows = os_info and os_info.sysname:match("Windows") ~= nil
        local function norm(path)
            return vim.fs.normalize(path)
        end

        -- Detect WSL2 environment (no built-in API; /proc/version check is standard).
        local function is_wsl_runtime()
            local proc_version = "/proc/version"
            local stat = vim.uv.fs_stat(proc_version)
            if not stat then
                return false
            end
            local ok, content = pcall(vim.fn.readfile, proc_version, "", 1)
            if not ok then
                return false
            end
            return content[1] and content[1]:lower():match("microsoft") ~= nil
        end

        -- Buffer-local keymaps attached via on_attach for each LSP-enabled buffer.
        local function on_attach(_, bufnr)
            local opts = function(desc)
                return { buffer = bufnr, desc = desc }
            end
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("Go to references"))
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
            vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, opts("Hover documentation"))
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename symbol"))
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
        end

        local base_config = {
            on_attach = on_attach,
            capabilities = build_capabilities(),
            flags = {
                debounce_text_changes = 1,
            },
        }

        apply_hover_theme()

        local server_names = {
            "clangd",
            "cssls",
            "html",
            "jsonls",
            "lua_ls",
            "marksman",
            "ols",
            "pyright",
            "vimls",
            "yamlls",
        }

        local is_wsl = is_wsl_runtime()

        -- Explicit cmd entries ensure PATH-based binaries are used, avoiding
        -- stale builds in the nvim-wsl Mason directory. PATH includes the
        -- up-to-date ~/.local/share/nvim/mason/bin/.
        local server_overrides = {
            -- lua_ls: Neovim runtime/plugin awareness
            lua_ls = {
                cmd = { "lua-language-server" },
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        workspace = {
                            checkThirdParty = false,
                            library = { vim.env.VIMRUNTIME },
                        },
                        diagnostics = {
                            globals = { "vim" },
                        },
                        telemetry = { enable = false },
                    },
                },
            },

            -- ols: Cross-platform Odin language server
            ols = {
                filetypes = { "odin" },
                cmd = is_windows
                    and { norm("C:/Users/Christopher/AppData/Local/ols/ols.exe") }
                    or { "ols" },
                init_options = {
                    checker_args = { "-strict-style" },
                    collections = is_windows and {
                        { name = "shared", path = norm("C:/Users/Christopher/scoop/apps/odin/current/shared") },
                        { name = "vendor", path = norm("C:/Users/Christopher/scoop/apps/odin/current/vendor") },
                        { name = "core",   path = norm("C:/Users/Christopher/scoop/apps/odin/current/core") },
                    } or is_wsl and {
                        { name = "shared", path = "/opt/Odin/shared" },
                        { name = "vendor", path = "/opt/Odin/vendor" },
                        { name = "core",   path = "/opt/Odin/core" },
                    } or nil,
                },
            },

            -- clangd: faster indexing, reduced background work
            --
            -- Inactive #if regions: clangd grays out code in preprocessor branches
            -- it considers inactive (e.g., #if SOME_UNDEFINED_MACRO). It does this
            -- by sending semantic tokens with type "comment" for those regions.
            -- This overrides treesitter highlighting and makes the code unreadable.
            --
            -- Fix: In highlights.lua, we clear @lsp.type.comment.c (and .cpp/.objc)
            -- so clangd's "comment" tokens have no effect. Treesitter then handles
            -- syntax highlighting normally for all code, including inactive regions.
            clangd = {
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--header-insertion=iwyu",
                    "--completion-style=detailed",
                },
            },

            -- cssls, html, jsonls: PATH-based cmd
            cssls = { cmd = { "vscode-css-language-server", "--stdio" } },
            html = { cmd = { "vscode-html-language-server", "--stdio" } },
            jsonls = {
                cmd = { "vscode-json-language-server", "--stdio" },
                settings = {
                    json = {
                        validate = { enable = true },
                    },
                },
            },

            -- marksman: PATH-based cmd
            marksman = { cmd = { "marksman", "server" } },

            -- pyright: PATH-based cmd
            pyright = { cmd = { "pyright-langserver", "--stdio" } },

            -- vimls: PATH-based cmd
            vimls = { cmd = { "vim-language-server", "--stdio" } },

            -- yamlls: PATH-based cmd
            yamlls = {
                cmd = { "yaml-language-server", "--stdio" },
                settings = {
                    yaml = {
                        keyOrdering = false,
                    },
                },
            },
        }

        local configured_servers = {}

        -- Merge base config with per-server overrides (preserves nested capabilities).
        local function merge_config(base, override)
            local merged = vim.tbl_deep_extend("force", {}, base, override)
            if override.capabilities then
                merged.capabilities = vim.tbl_deep_extend("force", {}, base.capabilities, override.capabilities)
            end
            return merged
        end

        -- Configure and enable each server.
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
