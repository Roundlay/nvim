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

            local function set_hover_hl()
                local palette = vim.g.vscode_light_popup
                if type(palette) ~= "table" then
                    palette = {
                        front = "#343434",
                        bg = "#F8F8F8",
                        border = "#DDDDDD",
                        muted = "#767676",
                        accent = "#0451A5",
                        link = "#0064c1",
                        code = "#0000FF",
                    }
                end

                vim.api.nvim_set_hl(0, "VscodeHoverNormal", { fg = palette.front, bg = palette.bg })
                vim.api.nvim_set_hl(0, "VscodeHoverBorder", { fg = palette.border, bg = palette.bg })
                vim.api.nvim_set_hl(0, "VscodeHoverTitle", { fg = palette.accent, bg = palette.bg, bold = true })
                vim.api.nvim_set_hl(0, "VscodeHoverMuted", { fg = palette.muted, bg = palette.bg })
                vim.api.nvim_set_hl(0, "VscodeHoverHeading", { fg = palette.accent, bg = palette.bg, bold = true })
                vim.api.nvim_set_hl(0, "VscodeHoverCode", { fg = palette.code, bg = palette.bg })
                vim.api.nvim_set_hl(0, "VscodeHoverLink", { fg = palette.link, bg = palette.bg, underline = true })
                vim.api.nvim_set_hl(0, "VscodeHoverStrong", { fg = palette.front, bg = palette.bg, bold = true })
                vim.api.nvim_set_hl(0, "VscodeHoverItalic", { fg = palette.front, bg = palette.bg, italic = true })
            end

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

            local winhl = table.concat({
                "NormalFloat:VscodeHoverNormal",
                "Normal:VscodeHoverNormal",
                "FloatBorder:VscodeHoverBorder",
                "FloatTitle:VscodeHoverNormal",
            }, ",")

            vim.lsp.buf.hover = function(config)
                set_hover_hl()

                config = config or {}
                config.focus_id = ms.textDocument_hover
                local win = api.nvim_get_current_win()
                local win_width = api.nvim_win_get_width(win)
                local win_height = api.nvim_win_get_height(win)
                local target_width = math.max(1, win_width - 12)
                local target_height = math.max(1, math.floor(win_height / 3))
                if config.border == nil then
                    config.border = {
                        { "█", "VscodeHoverBorder" },
                        { "▀", "VscodeHoverBorder" },
                        { "█", "VscodeHoverBorder" },
                        { "█", "VscodeHoverBorder" },
                        { "█", "VscodeHoverBorder" },
                        { "▄", "VscodeHoverBorder" },
                        { "█", "VscodeHoverBorder" },
                        { "█", "VscodeHoverBorder" },
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

                    do
                        local cleaned = {}
                        for i = 1, #contents do
                            local line = contents[i]
                            if not line:match("^```") then
                                cleaned[#cleaned + 1] = line
                            end
                        end
                        while cleaned[1] == "" do
                            table.remove(cleaned, 1)
                        end
                        while cleaned[#cleaned] == "" do
                            table.remove(cleaned, #cleaned)
                        end
                        contents = cleaned
                    end
                    format = "plaintext"

                    for i = 1, #contents do
                        contents[i] = " " .. contents[i] .. " "
                    end

                    local hover_buf, winid = lsp.util.open_floating_preview(contents, format, config)
                    if hover_buf and api.nvim_buf_is_valid(hover_buf) then
                        pcall(vim.treesitter.stop, hover_buf)
                        vim.bo[hover_buf].syntax = ""
                        vim.bo[hover_buf].filetype = ""
                    end
                    if winid and api.nvim_win_is_valid(winid) then
                        local ok = pcall(api.nvim_set_option_value, "winhighlight", winhl, { win = winid })
                        if not ok then
                            pcall(api.nvim_win_set_option, winid, "winhighlight", winhl)
                        end

                        local float_width = api.nvim_win_get_width(winid)
                        local float_height = api.nvim_win_get_height(winid)
                        local cursor_row = vim.fn.winline()
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
