-- nvim-lspconfig

return {
    "neovim/nvim-lspconfig",
    enabled = true,
    lazy = true,
    event = { "VimEnter", "BufReadPre", "BufNewFile" },
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

            local api = vim.api
            local lsp = vim.lsp
            local util = require("vim.lsp.util")
            local ms = require("vim.lsp.protocol").Methods
            local hover_ns = api.nvim_create_namespace("vscode_lsp_hover_range")

            local function client_positional_params(params)
                local win = api.nvim_get_current_win()
                return function(client)
                    local ret = util.make_position_params(win, client.offset_encoding)
                    if params then
                        ret = vim.tbl_extend("force", ret, params)
                    end
                    return ret
                end
            end

            vim.lsp.buf.hover = function(config)
                config = config or {}
                config.focus_id = ms.textDocument_hover
                local win = api.nvim_get_current_win()
                local win_width = api.nvim_win_get_width(win)
                local win_height = api.nvim_win_get_height(win)
                local target_width = math.max(1, win_width - 12)
                local target_height = math.max(1, math.floor(win_height / 3))
                local cursor_row = 0
                pcall(function()
                    cursor_row = api.nvim_win_call(win, function()
                        return vim.fn.winline()
                    end)
                end)
                if config.border == nil then
                    config.border = {
                        { "█", "FloatBorder" },
                        { "▀", "FloatBorder" },
                        { "█", "FloatBorder" },
                        { "█", "FloatBorder" },
                        { "█", "FloatBorder" },
                        { "▄", "FloatBorder" },
                        { "█", "FloatBorder" },
                        { "█", "FloatBorder" },
                    }
                end
                config.width = target_width
                config.max_width = target_width
                config.wrap_at = target_width
                config.max_height = target_height

                lsp.buf_request_all(0, ms.textDocument_hover, client_positional_params(), function(results, ctx)
                    local bufnr = assert(ctx.bufnr)
                    if api.nvim_get_current_buf() ~= bufnr then
                        return
                    end

                    local results1 = {}
                    for client_id, resp in pairs(results) do
                        local err, result = resp.err, resp.result
                        if err then
                            lsp.log.error(err.code, err.message)
                        elseif result then
                            results1[client_id] = result
                        end
                    end

                    if vim.tbl_isempty(results1) then
                        if config.silent ~= true then
                            vim.notify("No information available")
                        end
                        return
                    end

                    local contents = {}
                    local nresults = #vim.tbl_keys(results1)
                    local format = "markdown"

                    for client_id, result in pairs(results1) do
                        local client = assert(lsp.get_client_by_id(client_id))
                        if nresults > 1 then
                            contents[#contents + 1] = string.format("# %s", client.name)
                        end
                        if type(result.contents) == "table" and result.contents.kind == "plaintext" then
                            if nresults == 1 then
                                format = "plaintext"
                                contents = vim.split(result.contents.value or "", "\n", { trimempty = true })
                            else
                                contents[#contents + 1] = "```"
                                vim.list_extend(
                                    contents,
                                    vim.split(result.contents.value or "", "\n", { trimempty = true })
                                )
                                contents[#contents + 1] = "```"
                            end
                        else
                            vim.list_extend(contents, util.convert_input_to_markdown_lines(result.contents))
                        end

                        local range = result.range
                        if range then
                            local start = range.start
                            local end_ = range["end"]
                            local start_idx = util._get_line_byte_from_position(
                                bufnr,
                                start,
                                client.offset_encoding
                            )
                            local end_idx = util._get_line_byte_from_position(
                                bufnr,
                                end_,
                                client.offset_encoding
                            )
                            vim.hl.range(
                                bufnr,
                                hover_ns,
                                "LspReferenceTarget",
                                { start.line, start_idx },
                                { end_.line, end_idx },
                                { priority = vim.hl.priorities.user }
                            )
                        end

                        contents[#contents + 1] = "---"
                    end

                    contents[#contents] = nil
                    if vim.tbl_isempty(contents) then
                        if config.silent ~= true then
                            vim.notify("No information available")
                        end
                        return
                    end

                    for i = 1, #contents do
                        contents[i] = " " .. contents[i] .. " "
                    end

                    local _, winid = lsp.util.open_floating_preview(contents, format, config)
                    if winid and api.nvim_win_is_valid(winid) then
                        local float_width = api.nvim_win_get_width(winid)
                        local float_height = api.nvim_win_get_height(winid)
                        local row = math.min(cursor_row, math.max(0, win_height - float_height))
                        local col = math.max(0, math.floor((win_width - float_width) / 2))
                        pcall(api.nvim_win_set_config, winid, {
                            relative = "win",
                            win = win,
                            anchor = "NW",
                            row = row,
                            col = col,
                        })
                    end

                    api.nvim_create_autocmd("WinClosed", {
                        pattern = tostring(winid),
                        once = true,
                        callback = function()
                            api.nvim_buf_clear_namespace(bufnr, hover_ns, 0, -1)
                            return true
                        end,
                    })
                end)
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
            vim.keymap.set("n", "<leader>k", function()
                vim.lsp.buf.hover()
            end, opts("Hover documentation"))
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
            "ols",
            "pyright",
            "vimls",
            "yamlls",
        }

        local is_wsl = is_wsl_runtime()

        local function is_executable(cmd)
            return type(cmd) == "string" and vim.fn.executable(cmd) == 1
        end

        local function pick_cmd(candidates)
            for i = 1, #candidates do
                local cmd = candidates[i]
                if cmd and is_executable(cmd[1]) then
                    return cmd
                end
            end
            return nil
        end

        local odin_root = nil
        if is_windows then
            odin_root = norm("C:/Users/Christopher/scoop/apps/odin/current")
        elseif is_wsl then
            odin_root = "/opt/Odin"
        end

        local odin_bin = nil
        if odin_root then
            odin_bin = is_windows and norm(odin_root .. "/odin.exe") or (odin_root .. "/odin")
        end

        local ols_cmd = nil
        if is_windows then
            ols_cmd = pick_cmd({
                { "ols" },
                { norm("C:/Users/Christopher/AppData/Local/ols/ols.exe") },
            })
        else
            local mason_ols = vim.fn.stdpath("data") .. "/mason/bin/ols"
            ols_cmd = pick_cmd({
                { "ols" },
                { mason_ols },
            })
        end

        local ols_collections = nil
        if odin_root then
            local shared = odin_root .. "/shared"
            local vendor = odin_root .. "/vendor"
            local core = odin_root .. "/core"
            if is_windows then
                shared = norm(shared)
                vendor = norm(vendor)
                core = norm(core)
            end
            ols_collections = {
                { name = "shared", path = shared },
                { name = "vendor", path = vendor },
                { name = "core", path = core },
            }
        end

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
            ols = (function()
                local config = {
                    filetypes = { "odin" },
                    init_options = {
                        checker_args = "-strict-style",
                    },
                }

                if ols_cmd then
                    config.cmd = ols_cmd
                end

                if odin_root then
                    local path_sep = is_windows and ";" or ":"
                    config.cmd_env = {
                        ODIN_ROOT = odin_root,
                        PATH = odin_root .. path_sep .. (vim.env.PATH or ""),
                    }
                    config.init_options.odin_root_override = odin_root
                    config.init_options.odin_command = odin_bin
                end

                if ols_collections then
                    config.init_options.collections = ols_collections
                end

                return config
            end)(),

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
                init_options = {
                    -- Remove the default error limit (20) - show all errors
                    fallbackFlags = { "-ferror-limit=0" },
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
