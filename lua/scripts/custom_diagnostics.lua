if vim.g.vscode then
    return
end

local M = {}

-- Upvalue hoisting: reduce table lookups in hot path
local api = vim.api
local diagnostic = vim.diagnostic
local fn = vim.fn
local min = math.min
local max = math.max

-- Constants
local MAX_BANNERS_PER_LINE = 3
local ERROR = diagnostic.severity.ERROR

-- Pre-computed padding strings (0-300 spaces)
-- Eliminates string allocation in hot path
local padding = {}
for i = 0, 300 do
    padding[i] = (" "):rep(i)
end

-- Namespace for extmarks
local ns = api.nvim_create_namespace("custom_diagnostics")

-- Per-buffer cache: buf → { lnum → extmark_opts }
-- All string formatting done in rebuild_cache(), render() is pure lookup
local cache = {}

-- Per-buffer metadata for cache validation
local cache_meta = {}  -- buf → { win_width }

-- Module state
local provider = {}
local enabled = false
local autocmd_group = nil

-- Rebuild the cache for a buffer (cold path - on DiagnosticChanged)
-- All string operations happen here, not in render()
local function rebuild_cache(buf, win_width)
    cache[buf] = {}
    cache_meta[buf] = { win_width = win_width }

    local errs = diagnostic.get(buf, { severity = ERROR })
    if #errs == 0 then
        return
    end

    -- Group diagnostics by line number
    local grouped = {}
    for _, d in ipairs(errs) do
        local lnum = d.lnum
        if not grouped[lnum] then
            grouped[lnum] = {}
        end
        grouped[lnum][#grouped[lnum] + 1] = d
    end

    -- Build extmark opts for each line with errors
    for lnum, diags in pairs(grouped) do
        local text = api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1] or ""
        local indent = #text:match("^[\t ]*")
        local prefix = padding[indent] or (" "):rep(indent)
        local avail = max(1, win_width - indent)

        local virt_lines = {}
        local shown = min(MAX_BANNERS_PER_LINE, #diags)

        for i = 1, shown do
            -- Normalize message: collapse whitespace, trim trailing
            local msg = diags[i].message:gsub("[%s\r\n]+", " "):gsub("%s+$", "")

            -- Truncate if exceeds available width
            local msg_width = fn.strdisplaywidth(msg)
            if msg_width > avail then
                msg = msg:sub(1, avail - 1) .. "…"
                msg_width = avail
            end

            -- Build line with padding to fill window width
            local line = prefix .. msg
            local pad_needed = win_width - indent - msg_width
            if pad_needed > 0 then
                line = line .. (padding[pad_needed] or (" "):rep(pad_needed))
            end

            virt_lines[#virt_lines + 1] = { { line, "CustomDiagText" } }
        end

        -- Add truncation indicator if more errors than shown
        local hidden = #diags - MAX_BANNERS_PER_LINE
        if hidden > 0 then
            local trunc_msg = prefix .. string.format("… %d more error%s truncated …",
                hidden, hidden == 1 and "" or "s")
            local pad_needed = win_width - fn.strdisplaywidth(trunc_msg)
            if pad_needed > 0 then
                trunc_msg = trunc_msg .. (padding[pad_needed] or (" "):rep(pad_needed))
            end
            virt_lines[#virt_lines + 1] = { { trunc_msg, "CustomDiagText" } }
        end

        -- Store pre-built extmark options
        cache[buf][lnum] = {
            virt_lines = virt_lines,
            virt_lines_above = true,
            line_hl_group = "CustomDiagLine",
            hl_mode = "combine",
            priority = 1,
        }
    end
end

-- Render function (hot path - called per window redraw at 60+ Hz)
-- Pure table lookup: zero allocations, zero regex, zero strdisplaywidth calls
local function render(_, win, buf, topline, botline)
    -- Clear extmarks in visible range
    api.nvim_buf_clear_namespace(buf, ns, topline, botline + 1)

    -- Fast path: no cache for this buffer
    local buf_cache = cache[buf]
    if not buf_cache then
        return
    end

    -- Check if cache needs rebuild (window resize)
    local win_width = api.nvim_win_get_width(win)
    local meta = cache_meta[buf]
    if meta and meta.win_width ~= win_width then
        rebuild_cache(buf, win_width)
        buf_cache = cache[buf]
        if not buf_cache then
            return
        end
    end

    -- Pure lookup: set extmarks for visible error lines
    for lnum = topline, botline do
        local opts = buf_cache[lnum]
        if opts then
            api.nvim_buf_set_extmark(buf, ns, lnum, 0, opts)
        end
    end
end

local function enable()
    if enabled then
        return
    end
    api.nvim_set_decoration_provider(ns, provider)
    enabled = true
end

local function disable()
    if not enabled then
        return
    end
    api.nvim_set_decoration_provider(ns, {})
    enabled = false
end

local function setup_autocmds()
    if autocmd_group then
        return
    end

    autocmd_group = api.nvim_create_augroup("CustomDiagnosticsFormatter", { clear = true })

    -- Disable rendering in insert mode
    api.nvim_create_autocmd("InsertEnter", {
        group = autocmd_group,
        callback = disable,
    })

    -- Re-enable rendering when leaving insert mode
    api.nvim_create_autocmd("InsertLeave", {
        group = autocmd_group,
        callback = function()
            enable()
            vim.schedule(function()
                diagnostic.show(nil, 0)
                vim.cmd("redraw!")
            end)
        end,
    })

    -- Rebuild cache when diagnostics change (cold path)
    api.nvim_create_autocmd("DiagnosticChanged", {
        group = autocmd_group,
        callback = function(args)
            local buf = args.buf
            if not api.nvim_buf_is_valid(buf) then
                return
            end

            -- Get window width from first window showing this buffer
            local wins = fn.win_findbuf(buf)
            local win_width = 80  -- fallback
            if #wins > 0 and api.nvim_win_is_valid(wins[1]) then
                win_width = api.nvim_win_get_width(wins[1])
            end

            -- Rebuild cache (all string formatting happens here)
            rebuild_cache(buf, win_width)

            -- Trigger redraw for all windows showing this buffer
            vim.schedule(function()
                for _, w in ipairs(wins) do
                    if api.nvim_win_is_valid(w) then
                        api.nvim_win_call(w, function()
                            vim.cmd("redraw!")
                        end)
                    end
                end
            end)
        end,
    })

    -- Clear cache when buffer is deleted
    api.nvim_create_autocmd("BufDelete", {
        group = autocmd_group,
        callback = function(args)
            cache[args.buf] = nil
            cache_meta[args.buf] = nil
        end,
    })
end

function M.setup()
    if vim.g._custom_diag_loaded then
        return M
    end
    vim.g._custom_diag_loaded = true

    provider.on_win = render

    diagnostic.config({
        virtual_text = false,
        virtual_lines = false,
        underline = false,
        signs = false,
        update_in_insert = false,
    })

    setup_autocmds()
    enable()

    return M
end

function M.enable()
    enable()
end

function M.disable()
    disable()
end

M.setup()

return M
