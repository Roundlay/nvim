-- scripts.lua
if vim.g.vscode then
    return
end

-- Module boiler-plate

---@type table<string,any>
local M = _G.M or {}
_G.M = M  -- expose for other modules/old code paths

-------------------------------------------------------------------------------

-- C Return Type Helper
-- Shows the return type of C functions inline alongside the function call.
-- E.g. `int foo(int a, int b);` becomes `int foo(int a, int b); ← int`
-- This also works for functions called from header files.
-- E.g. `fopen(path, "rb")` becomes `fopen(path, "rb"); ← FILE*`

-- [!] TODO: Our solution seems to occassinally report the wrong return type. Example:
-- `fread(buf, size, count, file)` reports `<- unsigned long long` instead of `<- size_t`.

local MAX_CONCURRENT_HOVERS = 6

local c_return_retries = {} ---@type table<integer,integer> -- bufnr → retry-count
local c_return_parsers = {} ---@type table<integer,any>     -- bufnr → parser cache
local c_return_changedtick = {} ---@type table<integer,integer> -- bufnr → changedtick
local c_return_states = {} ---@type table<integer, table>   -- per-buffer worker state
local c_return_queries = {} ---@type table<string, any>     -- cached Tree-sitter queries

-- One namespace for all extmarks so we can clear/update them deterministically.
local c_return_ns = vim.api.nvim_create_namespace('c_return_types')

-- Track extmark ids we own per buffer so we can update/delete incrementally.
local c_return_marks = {} ---@type table<integer, table<integer, table>> -- bufnr → { row → mark_info }

local function extract_hover_text(res)
    if not res then return nil end
    local contents = res.contents
    if not contents then return nil end
    local t = type(contents)
    if t == "string" then
        return contents
    elseif t == "table" then
        if contents.value then
            return contents.value
        end
        if vim.tbl_islist(contents) then
            for _, entry in ipairs(contents) do
                if type(entry) == "string" then
                    return entry
                elseif type(entry) == "table" and entry.value then
                    return entry.value
                end
            end
        end
    end
    return nil
end

local function normalize_return_type(return_type)
    if not return_type or return_type == "" or return_type == "void" then
        return nil
    end
    local cleaned = return_type
        :gsub("%s*%(aka[^)]+%)", "")
        :gsub("(%S)%s+(%[%])", "%1%2")
        :gsub("(%S)%s+%*", "%1*")
        :gsub("%s+", " ")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
    return cleaned ~= "" and cleaned or nil
end

local function clamp_position(bufnr, row, col)
    if row < 0 then
        return nil, nil
    end
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if row >= line_count then
        return nil, nil
    end
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    local max_col = #line
    if col > max_col then
        col = max_col
    elseif col < 0 then
        col = 0
    end
    return row, col
end

function M:show_c_return_types()
    -- Only process C/C++ files.
    local ft = vim.bo.filetype
    if ft ~= 'c' and ft ~= 'cpp' and ft ~= 'h' then
        return
    end

    -- clangd (and some other servers) can show their own return-type inlay hints
    -- which would duplicate the helper text we are about to render. Disable
    -- inlay hints for this buffer to avoid visual clutter. (Neovim ≥0.10)
    pcall(function()
        local ih = vim.lsp.inlay_hint
        if ih and type(ih.enable) == 'function' then
            local buf = vim.api.nvim_get_current_buf()
            local ok = pcall(ih.enable, buf, false)
            if not ok then pcall(ih.enable, false, buf) end
        end
    end)

    local bufnr = vim.api.nvim_get_current_buf()

    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if line_count == 0 or (line_count == 1 and (vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or "") == "") then
        return
    end

    local tick = vim.api.nvim_buf_get_changedtick(bufnr)
    if c_return_changedtick[bufnr] == tick then
        return
    end

    local mark_tbl = c_return_marks[bufnr]
    if not mark_tbl then
        mark_tbl = {}
        c_return_marks[bufnr] = mark_tbl
    else
        local updated_marks = {}
        for row, info in pairs(mark_tbl) do
            local new_row = row
            if info.id then
                local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, c_return_ns, info.id, {})
                if pos and pos[1] then
                    new_row = pos[1]
                    info.virt_col = pos[2] or info.virt_col
                else
                    -- Extmark vanished out from under us; drop the cached entry.
                    info.id = nil
                end
            end
            info.pending = true
            if info.id then
                updated_marks[new_row] = info
            end
        end
        mark_tbl = updated_marks
        c_return_marks[bufnr] = mark_tbl
    end

    -- Check if LSP is attached.
    local clients = vim.lsp.get_clients({bufnr = bufnr})
    if #clients == 0 then
        -- No LSP yet, so clear changedtick to force reprocess when LSP attaches.
        c_return_changedtick[bufnr] = nil
        return
    end

    local client
    for _, candidate in ipairs(clients) do
        if candidate:supports_method(vim.lsp.protocol.Methods.textDocument_hover) then
            client = candidate
            break
        end
    end
    if not client then
        c_return_changedtick[bufnr] = nil
        return
    end

    -- Cache parser for performance
    local parser = c_return_parsers[bufnr]
    if not parser then
        -- For .h files, try C parser first, fallback to cpp
        local lang = ft
        if ft == 'h' then
            lang = 'c'
        end

        -- Get tree-sitter parser with error handling
        local ok
        ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
        if not ok and ft == 'h' then
            -- Try cpp parser for .h files if c parser fails
            ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'cpp')
        end
        if not ok then
            return
        end
        c_return_parsers[bufnr] = parser
    end

    local tree = parser:parse()[1]
    if not tree then
        return
    end
    local root = tree:root()

    local lang = ft == 'h' and 'c' or ft
    local query = c_return_queries[lang]
    if not query then
        local ok
        ok, query = pcall(vim.treesitter.query.parse, lang, [[
        (call_expression
          function: (identifier) @func
        ) @call
        ]])
        if not ok then
            return
        end
        c_return_queries[lang] = query
    end

    local function_calls = {}
    local seen_rows = {}
    for id, node in query:iter_captures(root, bufnr, 0, -1) do
        if query.captures[id] == "func" then
            local parent = node:parent()
            if parent then
                local end_row, end_col = parent:end_()
                if not seen_rows[end_row] then
                    seen_rows[end_row] = true
                    local start_row, start_col = node:start()
                    table.insert(function_calls, {
                        start_row = start_row,
                        start_col = start_col,
                        end_row = end_row,
                        end_col = end_col,
                        func_name = vim.treesitter.get_node_text(node, bufnr) or "",
                    })
                end
            end
        end
    end

    if #function_calls == 0 then
        for row, info in pairs(mark_tbl) do
            if info.id then
                vim.api.nvim_buf_del_extmark(bufnr, c_return_ns, info.id)
            end
            mark_tbl[row] = nil
        end
        c_return_changedtick[bufnr] = tick
        c_return_retries[bufnr] = 0
        return
    end

    c_return_changedtick[bufnr] = tick

    local state = {
        bufnr = bufnr,
        client = client,
        run_id = ((c_return_states[bufnr] and c_return_states[bufnr].run_id) or 0) + 1,
        queue = {},
        queue_idx = 1,
        active = 0,
        tick = tick,
        had_success = false,
    }
    c_return_states[bufnr] = state

    local queue = state.queue
    local line_cache = {}

    for _, call in ipairs(function_calls) do
        local end_row = call.end_row
        local line = line_cache[end_row]
        if line == nil then
            line = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or ""
            line_cache[end_row] = line
        end
        local char_after = line:sub(call.end_col + 1, call.end_col + 1)
        local virt_col = (char_after == ";") and (call.end_col + 1) or call.end_col
        local signature = table.concat({ call.start_col, call.end_col, call.func_name }, ":")

        local existing = mark_tbl[end_row]
        if existing and existing.signature == signature then
            if existing.virt_col ~= virt_col and existing.return_type then
                local opts = {
                    id = existing.id,
                    virt_text = { { " ← " .. existing.return_type, "CReturnType" } },
                    virt_text_pos = "inline",
                    undo_restore = false,
                    invalidate = true,
                }
                existing.id = vim.api.nvim_buf_set_extmark(bufnr, c_return_ns, end_row, virt_col, opts)
                existing.virt_col = virt_col
            end
            existing.pending = false
        else
            table.insert(queue, {
                start_row = call.start_row,
                start_col = call.start_col,
                end_row = end_row,
                virt_col = virt_col,
                signature = signature,
            })
        end
    end

    local function finalize(state_ref)
        if c_return_states[bufnr] ~= state_ref then
            return
        end
        for row, info in pairs(mark_tbl) do
            if info.pending then
                if info.id then
                    vim.api.nvim_buf_del_extmark(bufnr, c_return_ns, info.id)
                end
                mark_tbl[row] = nil
            end
        end
        c_return_states[bufnr] = nil
        if state_ref.had_success then
            c_return_retries[bufnr] = 0
        else
            local retry = c_return_retries[bufnr] or 0
            if #queue > 0 and retry < 3 then
                c_return_retries[bufnr] = retry + 1
                c_return_changedtick[bufnr] = nil
                vim.defer_fn(function()
                    if vim.api.nvim_buf_is_valid(bufnr) then
                        M:show_c_return_types()
                    end
                end, 200 * (retry + 1))
            else
                c_return_retries[bufnr] = 0
            end
        end
    end

    if #queue == 0 then
        finalize(state)
        return
    end

    local function dispatch_next(state_ref)
        if c_return_states[bufnr] ~= state_ref then
            return
        end

        while state_ref.active < MAX_CONCURRENT_HOVERS and state_ref.queue_idx <= #queue do
            local item = queue[state_ref.queue_idx]
            state_ref.queue_idx = state_ref.queue_idx + 1
            state_ref.active = state_ref.active + 1

            local params = vim.lsp.util.make_position_params(0, state_ref.client.offset_encoding)
            params.position.line = item.start_row
            params.position.character = item.start_col

            state_ref.client.request('textDocument/hover', params, function(err, result)
                state_ref.active = state_ref.active - 1

                if c_return_states[bufnr] ~= state_ref then
                    return
                end

                local row, col = clamp_position(bufnr, item.end_row, item.virt_col)
                if not row then
                    local stale = mark_tbl[item.end_row]
                    if stale and stale.id then
                        vim.api.nvim_buf_del_extmark(bufnr, c_return_ns, stale.id)
                    end
                    mark_tbl[item.end_row] = nil
                    if state_ref.active == 0 and state_ref.queue_idx > #queue then
                        finalize(state_ref)
                    else
                        dispatch_next(state_ref)
                    end
                    return
                end
                if col ~= item.virt_col then
                    item.virt_col = col
                end

                local return_type = nil
                if not err and result then
                    local content = extract_hover_text(result)
                    if content then
                        local candidate = content:match("→%s*`([^`]+)`")
                        return_type = normalize_return_type(candidate)
                    end
                end

                local key = row
                local current_mark = mark_tbl[key]
                if return_type then
                    local opts = {
                        virt_text = { { " ← " .. return_type, "CReturnType" } },
                        virt_text_pos = "inline",
                        undo_restore = false,
                        invalidate = true,
                    }
                    if current_mark and current_mark.signature == item.signature then
                        opts.id = current_mark.id
                    elseif current_mark and current_mark.id then
                        vim.api.nvim_buf_del_extmark(bufnr, c_return_ns, current_mark.id)
                    end

                    local id = vim.api.nvim_buf_set_extmark(bufnr, c_return_ns, row, col, opts)
                    mark_tbl[key] = {
                        id = id,
                        signature = item.signature,
                        return_type = return_type,
                        virt_col = col,
                        pending = false,
                    }
                    state_ref.had_success = true
                else
                    if current_mark and current_mark.id then
                        vim.api.nvim_buf_del_extmark(bufnr, c_return_ns, current_mark.id)
                    end
                    mark_tbl[key] = nil
                end

                if state_ref.active == 0 and state_ref.queue_idx > #queue then
                    finalize(state_ref)
                else
                    dispatch_next(state_ref)
                end
            end, bufnr)
        end

        if state_ref.active == 0 and state_ref.queue_idx > #queue then
            finalize(state_ref)
        end
    end

    dispatch_next(state)
end

--[[

-- Setup autocmd group
local group = vim.api.nvim_create_augroup("CReturnTypeHelper", { clear = true })

-- Trigger on buffer events and LSP attach
vim.api.nvim_create_autocmd({"BufReadPost", "BufWritePost", "InsertLeave", "TextChanged"}, {
    group = group,
    pattern = {"*.c", "*.h", "*.cpp", "*.cc", "*.cxx", "*.hpp"},
    callback = function()
        -- Call directly without delay for better responsiveness
        M:show_c_return_types()
    end,
})

-- Special handling for initial file load from command line
vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
        local ft = vim.bo.filetype
        if ft == 'c' or ft == 'cpp' or ft == 'h' then
            -- Longer delay for initial startup
            vim.defer_fn(function()
                M:show_c_return_types()
            end, 500)
        end
    end,
})

-- Also trigger when LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
        local bufnr = args.buf
        local ft = vim.bo[bufnr].filetype
        if ft == 'c' or ft == 'cpp' or ft == 'h' then
            vim.defer_fn(function()
                M:show_c_return_types()
            end, 100)
        end
    end,
})

-- Clean up cached data when buffer is deleted
vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(args)
        c_return_changedtick[args.buf] = nil
        c_return_retries[args.buf] = nil
        c_return_parsers[args.buf] = nil
        c_return_marks[args.buf] = nil
    end,
})
--]]

-- [ ] Extremely slow on big files; need way to disable with command; need to work on perf.
M:show_c_return_types()

-- -----------------------------------------------------------------------------

-- Custom Diagnostics Formatting & Highlighting
-- This is a custom diagnostics renderer that uses extmarks to display
-- diagnostics above the target line.

-- TODO FEATURE Don't display diagnostics if the file has been modified but not saved.
-- TODO: Occasionally, diagnostics aren't cleared up properly, and they remain in place, often at the end of the file, even after the offending code has been removed.

function M:custom_diagnostics_formatter()

    -- TODO: Rename namespace
    local ns = vim.api.nvim_create_namespace("custom_diagnostics")

    vim.diagnostic.config({
        virtual_text     = false,
        virtual_lines    = false,
        underline        = false,
        signs            = false,
        update_in_insert = false,
    })

    local provider = {}

    -- Show at most this many diagnostic banners per source line
    local MAX_VIRTUAL_DIAGNOSTIC_BANNERS_PER_TARGET = 3

    provider.on_win = function(_, win, buf, topline, botline)
        vim.api.nvim_buf_clear_namespace(buf, ns, topline, botline + 1)

        -- Pull visible error diagnostics.
        local errs = vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
        if #errs == 0 then return end

        local grouped = {} -- [lnum] = { diag1, diag2, … }
        for _, d in ipairs(errs) do
            if d.lnum >= topline and d.lnum <= botline then
                grouped[d.lnum] = grouped[d.lnum] or {}
                table.insert(grouped[d.lnum], d) -- Preserves original order.
            end
        end
        if next(grouped) == nil then return end

        -- Render one extmark per lnum, with all virt_lines inside it.
        local win_width = vim.api.nvim_win_get_width(win)

        for lnum, diags in pairs(grouped) do
            -- Instead of:
            -- local indent   = vim.fn.indent(lnum + 1)
            local text = (vim.api.nvim_buf_get_lines(buf, lnum, lnum+1, false)[1] or "")
            local indent = #text:match("^[\t ]*")

            local prefix   = (" "):rep(indent)
            local avail    = math.max(1, win_width - indent)

            local virt_lines = {}

            -- Real error banners
            for i = 1, math.min(MAX_VIRTUAL_DIAGNOSTIC_BANNERS_PER_TARGET, #diags) do
                local msg = diags[i].message:gsub("[%s\r\n]+", " "):gsub("%s+$", "")
                if vim.fn.strdisplaywidth(msg) > avail then
                    msg = msg:sub(1, avail - 1) .. "…"
                end

                local line = prefix .. msg
                local pad  = win_width - vim.fn.strdisplaywidth(line)
                if pad > 0 then line = line .. (" "):rep(pad) end

                table.insert(virt_lines, { { line, "CustomDiagText" } })
            end

            local hidden = #diags - MAX_VIRTUAL_DIAGNOSTIC_BANNERS_PER_TARGET
            if hidden > 0 then
                local msg = prefix .. string.format("… %d more error%s truncated …", hidden, hidden == 1 and "" or "s")
                local pad = win_width - vim.fn.strdisplaywidth(msg)
                if pad > 0 then msg = msg .. (" "):rep(pad) end

                table.insert(virt_lines, { { msg, "CustomDiagText" } })
            end

            -- one extmark does the whole job
            vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
                virt_lines       = virt_lines,
                virt_lines_above = true,
                line_hl_group    = "CustomDiagLine",
                hl_mode          = "combine",
                priority         = 1,
            })
        end
    end

    local enabled = false
    local function enable()
        if enabled then return end
        vim.api.nvim_set_decoration_provider(ns, provider)
        enabled = true
    end

    local function disable()
        if not enabled then return end
        vim.api.nvim_set_decoration_provider(ns, {})
        enabled = false
    end

    enable()


    vim.api.nvim_create_autocmd("InsertEnter", {
        callback = disable
    })

    vim.api.nvim_create_autocmd("InsertLeave", {
        callback = function(args)
            enable()
            vim.schedule(function()
                vim.diagnostic.show(nil, 0)
                vim.cmd("redraw!")
            end)
        end,
    })

    vim.api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function(args)
            vim.schedule(function()
                for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
                    vim.api.nvim_win_call(win, function() vim.cmd("redraw!") end)
                end
            end)
        end,
    })

end

M:custom_diagnostics_formatter()

-------------------------------------------------------------------------------
-- Custom Numberline

-- [!] TODO Benchmark this.

-- [ ] TODO Find a way to reduce calls to the Vim/Neovim API. E.g. we call
-- vim.api.nvim_win_get_option() and vim.api.nvim_buf_get_option() a lot. We
-- should be able to cache these values and only update them when they change.
-- But we also need to ensure that each buffer/window is updated independently.
-- There may be no way around the current implementation?

-- [ ] TODO Doesn't work in help files. Is that because they're READ-ONLY?

-- [ ] TODO Add support for plugin style setup functions within package
-- managers, e.g. Lazy. I.e. refactor this as a plugin.
    -- [ ] Check Lazy documentation and other plugins.
    -- [ ] Add support for toggleable options like colours, highlighting the
    -- active line in the numberline, padding, etc.

-- [ ] TODO Rename this!

function M:pretty_line_numbers()
    -- [!] Document functionality. E.g. why we need to get the winid every
    -- iteration (to ensure all windows update independently, etc.).
    if vim.g._pln_loaded then return end
    vim.g._pln_loaded = true

    local buf_digit_counts = {}

    local excluded_filetypes = {
        help = true,
        lazy = true,
        TelescopePrompt = true,
    }

    local excluded_buftypes = {
        terminal = true,
        prompt = true,
        nofile = true,
    }

    local function update_window(winid)
        winid = winid or vim.api.nvim_get_current_win()
        if not vim.api.nvim_win_is_valid(winid) then return end

        local num_on  = vim.api.nvim_win_get_option(winid, 'number')
        local rnum_on = vim.api.nvim_win_get_option(winid, 'relativenumber')

        if not num_on and not rnum_on then
            -- User disabled both -> clear our statuscolumn & return early.
            if vim.api.nvim_win_get_option(winid, 'statuscolumn') ~= '' then
                pcall(vim.api.nvim_win_set_option, winid, 'statuscolumn', '')
            end
            return
        end

        local buf = vim.api.nvim_win_get_buf(winid)
        if not vim.api.nvim_buf_is_valid(buf) then return end

        local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
        local bt = vim.api.nvim_get_option_value("buftype",  { buf = buf })

        if excluded_filetypes[ft] or excluded_buftypes[bt] then
            return
        end

        local cursor_line_status = vim.api.nvim_get_option_value("cursorline", { scope = "global", win = winid })

        if not cursor_line_status then
            -- Remember the user’s original cursorlineopt just once per window
            if vim.w._pln_user_cursorlineopt == nil then
                vim.w._pln_user_cursorlineopt =
                vim.api.nvim_get_option_value('cursorlineopt', { win = winid })
            end

            -- Keep the highlight invisible but allow CursorLineNr to refresh
            -- [!] TODO Document this! I.e. we're actually highlighting the
            -- active line number in the numberline with the cursorline feature,
            -- but hiding the actual line highlight if the user hasn't enabled
            -- cursorline highlighting.
            vim.api.nvim_set_option_value('cursorlineopt', 'number', { win = winid })
            vim.api.nvim_set_option_value('cursorline', true,        { win = winid })

            vim.w._pln_cursorline_forced = true
        end

        -- Literally: How many decimal line_count does my total line-count have?
        local line_count = #tostring(vim.api.nvim_buf_line_count(buf))
        -- [!] TODO The n-cell gutter width should be a customisable setting
        -- available in the configuration. '+1' lines the edge of the code up
        -- with the right side of our numberline. +1 adds a single column gap
        -- between the code and the numberline.
        local required_width = math.max(2, line_count + 2) -- +2 = one-cell gutter between code and numberline.

        if vim.api.nvim_win_get_option(winid, 'numberwidth') ~= required_width then
            pcall(vim.api.nvim_win_set_option, winid, 'numberwidth', required_width)
        end

        local use_relative = vim.api.nvim_win_get_option(winid, 'relativenumber') and 1 or 0
        local formatted_status_column = string.format('%%!v:lua.FormatLineNr(%d,%d)', line_count, use_relative)

        if vim.api.nvim_win_get_option(winid, 'statuscolumn') ~= formatted_status_column then
            pcall(vim.api.nvim_win_set_option, winid, 'statuscolumn', formatted_status_column)
        end

        buf_digit_counts[buf] = line_count
    end

    for _, window in ipairs(vim.api.nvim_list_wins()) do
        update_window(window)
    end

    -- [!] TODO Is it bad that we're setting up a new augroup every time we
    -- call this function? I.e. we should only set up the autocommands once, not
    -- every time we call this function. So maybe we should move all these to
    -- the autocommands file?
    -- [!] TODO Find a way to simplify this. I.e. we don't need to create a new
    -- augroup every time we call this function? Do we?
    -- [!] TODO Document these autocommands.

    local aug = vim.api.nvim_create_augroup('PrettyLineNumbers', { clear = true })

    vim.api.nvim_create_autocmd({'BufWinEnter', 'WinEnter', 'WinNew', 'WinResized'}, {
        group = aug,
        callback = function(ev) update_window(ev.win) end
    })

    vim.api.nvim_create_autocmd("OptionSet", {
        group   = aug,
        pattern = {"relativenumber", "number"},
        callback = function() update_window() end,
    })

    vim.api.nvim_create_autocmd({'TextChanged','TextChangedI','BufWritePost'}, {
        group = aug,
        callback = function(ev)
            local buf = ev.buf
            if not vim.api.nvim_buf_is_valid(buf) then return end

            local line_count = vim.api.nvim_buf_line_count(buf)
            local new_digits = #tostring(line_count)
            local old_digits = buf_digit_counts[buf] or 0

            if new_digits ~= old_digits then
                buf_digit_counts[buf] = new_digits
                for _, window_id in ipairs(vim.fn.win_findbuf(buf)) do
                    update_window(window_id)
                end
            end
        end,
    })

    vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "cursorline",
        group   = aug,
        callback = function(ev)
            local w = ev.win
            local now_on = vim.api.nvim_get_option_value('cursorline', { scope = "global", win = w })

            if now_on then
                -- User turned cursorline ON → restore their original setting.
                local restore = vim.w._pln_user_cursorlineopt or 'line,number'
                vim.api.nvim_set_option_value('cursorlineopt', restore, { scope = "global", win = w })
                vim.w._pln_cursorline_forced = false
            else
                -- User turned cursorline OFF → keep numbers updating silently.
                vim.api.nvim_set_option_value('cursorlineopt', 'number', { scope = "global", win = w })
                vim.w._pln_cursorline_forced = true
            end
            update_window(w)
        end,
    })

    -- [!] TODO Surely there's a better way to do this that doesn't involve
    -- string manipulation? String builder? Abusing the Vim API directly?

    _G.FormatLineNr = function(width, use_rel)
        if vim.v.virtnum ~= 0 then return '' end
        local rel = vim.v.relnum
        local num = (use_rel == 1 and rel ~= 0) and math.abs(rel) or vim.v.lnum
        local hl  = (rel == 0) and 'CursorLineNr' or 'LineNr'
        local padded = ('%0' .. width .. 'd'):format(num)
        local zeros, rest = padded:match('^(0*)(.*)$')

        return ('%%#LineNrPrefix#%s%%#%s#%s %%*'):format(zeros, hl, rest)
    end
end

M:pretty_line_numbers()

-- -------------------------------------------------------------------------- --

-- WOAH THERE, COWBOY

-- function M.cowboy()
-- 	---@type table?
-- 	local id
-- 	local ok = true
-- 	for _, key in ipairs({ "h", "j", "k", "l", "+", "-" }) do
-- 		local count = 0
-- 		local timer = assert(vim.loop.new_timer())
-- 		local map = key
-- 		vim.keymap.set("n", key, function()
-- 			if vim.v.count > 0 then
-- 				count = 0
-- 			end
-- 			if count >= 10 then
-- 				ok, id = pcall(vim.notify, "Hold it Cowboy!", vim.log.levels.WARN, {
-- 					icon = ">:(",
-- 					replace = id,
-- 					keep = function()
-- 						return count >= 10
-- 					end,
-- 				})
-- 				if not ok then
-- 					id = nil
-- 					return map
-- 				end
-- 			else
-- 				count = count + 1
-- 				timer:start(2000, 0, function()
-- 					count = 0
-- 				end)
-- 				return map
-- 			end
-- 		end, { expr = true, silent = true })
-- 	end
-- end

-- -------------------------------------------------------------------------- --

-- RELOAD SCRIPTS

-- _G.ReloadScripts = function()
--     local initial_state = package.loaded['scripts']
--     if package.loaded['scripts'] then
--         package.loaded['scripts'] = nil
--         if package.loaded['scripts'] ~= initial_state then
--             require('scripts')
--             if package.loaded['scripts'] == initial_state then
--                 vim.notify(os.date("[%H:%M:%S] ").."Scripts module reloaded successfully.", vim.log.levels.INFO)
--             end
--         end
--     end
-- end

-- -------------------------------------------------------------------------- --

-- WRAPPIN'

-- Reversably soft wrap lines that are longer than n characters at the nth
-- column. The default wrap column is column 80. The script respects comment
-- prefixes and inline comments. It also respects the initial indentation of the
-- first line in the selection.

--[[
[!] TODO BUG 
Consider the following chunk of text:

## TL;DR (do this in order)

1. **Treat LSLib as the ground truth and oracle.** Convert LSF→LSX during indexing; do *not* block on your v7 binary parser. LSLib 1.18.7+ supports LSF v7 and fixed the BG3 UUID endianness change, which bit a lot of people. ([GitHub][1])

2. **Fix your PAK v18 reader** (offset packing, flags, and file‑table decompression) so you can reliably stream files from `Shared*.pak`, `Gustav*.pak`, `Materials.pak`, `Textures*.pak`, and `VirtualTextures*.pak`. Use the structures in LSLib’s `PackageFormat.cs` / `PackageReader.cs` as the spec. ([GitHub][2])

3. **Build a GUID→(file, xpath) index from LSX** (VisualBank, MaterialBank, TextureBank). Use Multitool’s “Index/Search” as a reference for what “complete” looks like. ([Baldur's Gate 3 Wiki][3], [wiki.bg3.community][4])

4. **Recursive resolver (the heart of your extractor):**
   Visual → Materials (incl. nested template/material refs) → Textures **and** VirtualTextures (via `GTexFileName`) → files (`.gr2`, `.dds`, `.gts/.gtp`). The community docs and examples call out these exact banks and fields. ([Baldur's Gate 3 Wiki][5], [wiki.bg3.community][6])

5. **Virtual textures:** map `GTexFileName` (32‑hex) → its tileset/page (`.gts`/`.gtp`) and export the layers. LSLib added *virtual texture* generation/export and has a doc + numerous bugfixes specific to `GTP/GTS`—lean on it. Also see the bg3.wiki guide on *finding* virtual textures (it shows where `GTexFileName` lives). ([GitHub][1], [Baldur's Gate 3 Wiki][7])

6. **Only after the extractor ships**: copy LSLib’s LSF v7 node/attribute/value layout (don’t guess). You already rediscovered several pitfalls that are solved there.
```

When we run the Wrappin function on this selection, i.e. by going into visual
section mode and selecting it all, it results in the following:

```
## TL;DR (do this in order)
```

Effectively removing/deleting everything... This may be related to the fact that the first line starts with `##` which might be confusing a header for a comment prefix. We need to add more robust handling for headers and other non-comment prefixes. We need more robust handling of comments in general!
--]]


--[[
[ ] TODO FEATURE
We should add support for rewrapping multiple lines, where one or more
of the lines are already wrapped. E.g. if we have a selection of 4 lines,
where lines 1, 2, and 4 are already within the wrap boundary, but 3 has a
length longer than our wrap column, we should be able to reflow everything
below the offending line.
--]]


--[[
[ ] TODO IDEA
We should probably have some kind of way to allow the user to store the original
layout of the text they want to wrap in some kind of buffer, perhaps on disk, so
that we can perfect revert to the original layout if needed. We'd need to be
careful about how we implement this so that we don't just end up reimplementing
"undo". I.e. if the user alters the text after using Wrappin', and then the user
wants to revert to the original layout, how do we deal with this? I guess all we
really care about are things like, "were the lines spaced out in a certain way,"
or "where lines indented and where?" That kind of thing
--]]

_G.Wrappin = function()
    local start_line = vim.fn.getpos("'<")[2] - 1
    local end_line = vim.fn.getpos("'>")[2] - 1
    local max_width = 80

    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line+1, false)
    if #lines == 0 then return end
    -- Analyze first line for comment pattern
    local initial_indent = lines[1]:match("^(%s*)") or ""
    local comment_prefix = lines[1]:match("^%s*([%-/]+%s*)") or ""
    local first_is_comment = comment_prefix ~= "" and lines[1]:match("^%s*" .. vim.pesc(comment_prefix)) ~= nil
    -- Detect if we're in wrapped state (B) or single-line state (A)
    -- Only consider as wrapped if selection has multiple lines AND every line
    -- starts with a comment prefix (avoids joining arbitrary multi-line code).
    local is_wrapped = false
    if #lines > 1 and first_is_comment then
        is_wrapped = true
        for i = 2, #lines do
            if not lines[i]:match("^%s*" .. vim.pesc(comment_prefix)) then
                is_wrapped = false
                break
            end
        end
    end
    if is_wrapped then
        -- UNWRAP: Join lines, removing duplicate comment prefixes
        local content = {}
        for _, line in ipairs(lines) do
            local cleaned = line:gsub("^%s*" .. vim.pesc(comment_prefix), "", 1)
            table.insert(content, cleaned)
        end
        local single_line = initial_indent .. comment_prefix ..
                           table.concat(content, " "):gsub("%s+", " ")
        vim.api.nvim_buf_set_lines(0, start_line, end_line+1, false, {single_line})
    else
        -- WRAP: Split into multiple lines with comment prefix
        local content = lines[1]
        local words = {}
        -- If this is already a comment line, don't look for inline comments
        if content:match("^%s*[%-/]+%s+") then
            content = content:gsub("^%s*" .. vim.pesc(comment_prefix), "")
            for word in content:gmatch("%S+") do
                table.insert(words, word)
            end
        else
            -- Only look for inline comments in non-comment lines
            content = content:gsub("^%s*" .. vim.pesc(comment_prefix), "")
            local code_part, comment_part = content:match("^(.-)%s*(//.*)$")
            if code_part and comment_part then
                -- Process code part
                for word in code_part:gmatch("%S+") do
                    table.insert(words, word)
                end
                -- Add comment as a single unit
                table.insert(words, comment_part)
            else
                -- No inline comment, process normally
                for word in content:gmatch("%S+") do
                    table.insert(words, word)
                end
            end
        end
        local new_lines = {}
        local current_line = initial_indent .. comment_prefix
        local line_width = #current_line
        for i, word in ipairs(words) do
            local space_needed = i > 1 and 1 or 0
            local word_width = #word + space_needed
            -- Special handling for comments, but only if we're not already in a comment
            local is_comment = not content:match("^%s*[%-/]+%s+") and word:match("^//")
            if is_comment then
                -- If current line plus comment would exceed width, wrap first
                if line_width > #initial_indent then
                    table.insert(new_lines, current_line)
                    current_line = initial_indent
                    line_width = #current_line
                end
                -- Add comment as a single unit
                current_line = current_line .. word
                line_width = #current_line
            else
                -- Normal word handling
                if line_width + word_width > max_width then
                    table.insert(new_lines, current_line)
                    current_line = initial_indent .. comment_prefix .. word
                    line_width = #current_line
                else
                    current_line = current_line .. (space_needed > 0 and " " or "") .. word
                    line_width = line_width + word_width
                end
            end
        end
        if current_line ~= "" then
            table.insert(new_lines, current_line)
        end
        vim.api.nvim_buf_set_lines(0, start_line, end_line+1, false, new_lines)
    end
end

-- -------------------------------------------------------------------------- --

-- TAG WRAPPER

-- Wrap normal and visual block selections with configurable tags.
-- Tags are placed on their own lines above and below the selection.
-- Example: <tag>selection</tag> or [START]selection[END]

_G.WrapWithTags = function()
    -- First, exit visual mode if we're in it to ensure marks are set
    local mode = vim.api.nvim_get_mode().mode
    if mode == 'v' or mode == 'V' or mode == '\22' then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'n', false)
        -- Small delay to ensure visual mode exit completes
        vim.cmd("sleep 10m")
    end
    
    local start_tag = vim.fn.input('Start tag (e.g. <div>, [START]): ')
    if start_tag == "" then return end
    
    local end_tag = vim.fn.input('End tag (e.g. </div>, [END]): ')
    if end_tag == "" then return end
    
    local buf = vim.api.nvim_get_current_buf()
    
    -- Check if we have visual marks
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local has_visual_selection = start_pos[2] ~= 0 and end_pos[2] ~= 0
    
    if not has_visual_selection then
        -- Normal mode: wrap current line
        local line_num = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_get_lines(buf, line_num - 1, line_num, false)
        if #lines == 0 then return end
        
        -- Get indentation from current line
        local indent = lines[1]:match("^(%s*)")
        
        -- Insert tags with same indentation
        local new_lines = {
            indent .. start_tag,
            lines[1],
            indent .. end_tag
        }
        
        vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, new_lines)
        
    elseif mode == '\22' or (start_pos[3] > 1 or end_pos[3] < 2147483647) then
        -- Visual block mode (when columns are constrained)
        local start_line = start_pos[2] - 1
        local end_line = end_pos[2] - 1
        local start_col = start_pos[3] - 1
        local end_col = end_pos[3] - 1
        
        -- Ensure columns are in correct order
        if start_col > end_col then
            start_col, end_col = end_col, start_col
        end
        
        local lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line + 1, false)
        if #lines == 0 then return end
        
        -- Extract block content and find common indentation
        local block_lines = {}
        local min_indent = math.huge
        
        for i, line in ipairs(lines) do
            local content = line:sub(start_col + 1, end_col + 1)
            table.insert(block_lines, content)
            
            -- Calculate indentation up to start column
            local indent_chars = line:sub(1, start_col):match("^(%s*)")
            if indent_chars then
                min_indent = math.min(min_indent, #indent_chars)
            end
        end
        
        -- Use the minimum indentation found
        local indent = (" "):rep(min_indent)
        
        -- Build replacement lines
        local new_lines = {indent .. start_tag}
        for _, content in ipairs(block_lines) do
            table.insert(new_lines, indent .. content:match("^%s*(.*)"))
        end
        table.insert(new_lines, indent .. end_tag)
        
        -- Calculate where to insert the wrapped content
        -- Insert at the beginning of the selection
        vim.api.nvim_buf_set_lines(buf, start_line, start_line, false, new_lines)
        
        -- Remove the original selected lines
        vim.api.nvim_buf_set_lines(buf, start_line + #new_lines, end_line + #new_lines + 1, false, {})
    else
        -- Visual line mode: wrap full lines
        local start_line = math.min(start_pos[2], end_pos[2]) - 1
        local end_line = math.max(start_pos[2], end_pos[2])
        
        local lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line, false)
        if #lines == 0 then return end
        
        -- Get indentation from first non-empty line
        local indent = ""
        for _, line in ipairs(lines) do
            if line:match("%S") then
                indent = line:match("^(%s*)") or ""
                break
            end
        end
        
        -- Build new lines array
        local new_lines = {indent .. start_tag}
        for _, line in ipairs(lines) do
            table.insert(new_lines, line)
        end
        table.insert(new_lines, indent .. end_tag)
        
        vim.api.nvim_buf_set_lines(buf, start_line, end_line, false, new_lines)
    end
end

-- -------------------------------------------------------------------------- --

-- VISREP
-- Replace visually selected text globally with a new string. Respects word boundaries, or not.

--[[

[!] Consider the following C struct. Simulated cursor represented by |.

struct |test_struct {
    int arr[1];
    int target;
};

struct test_struct test_struct = {{2, 7, 11, 15}, 9};

We need to handle tricky cases like this where the user selects the name of the struct, "test_struct", and wants to replace it with something else. The problem is, we have a type definition and a declarator with the same name, which is legal in C. If the user selects the struct name, from the cursor position above, when they use VisRep to replace the struct name, we want to offer the user the option to replace the string in a smart way. That is, we currently offer boundary and anywhere modes, which is great. Perhaps we need to either 1) make boundary include this LSP style context awareness (not sure if we can come up with an algorithm that's language agnostic and doesn't require an LSP, or 2), add a third mode called "context aware" or something, which uses LSP to determine the context of the selection and only offers matches in the same context. E.g. if the user selects "test_struct" in the type definition, we only offer matches that are also type definitions. If they select "test_struct" in the declarator, we only offer matches that are also declarators. This would require LSP support, but would be a powerful feature for users who have LSP set up. Because this would require LSP support we'd want to make this optional, I guess. The ideal solution though is one where contextual mode doesn't require an LSP. Perhaps in this contextual mode, the user gets a second cursor where they can select "context". I.e. the user starts with "test_struct" selected, then they press a key to enter "context selection mode", which places a second cursor in the file. The user can then select "struct" with the second cursor, and then when they press enter, we only offer matches for "test_struct" that are also preceded by "struct". This would be a powerful feature that doesn't require LSP support, but would require some UI/UX design to make it work well, and this may not work for all languages... Probably better to just say, "If you have an LSP running in this buffer, for this language, we'll use it to turn on this contextual mode for you," and just do that automatically or something. OR, we could offer some limited regular expression style thing, ideally using Vim's own regex style to be honest, as we might with the substitution command or something like that, where the user can just selected `test_struct` as in the struct, and then add something to the end or something like they might in the text substitution command? Actually, no, we don't want to start adding complexity like that. Any solution should be "tabbable". I.e. a contextual mode that let's you... something.

--]]

-- [!] When I change instances of 'pos' below to 'ps' and then run VisRep on 'ps' to change them back to 'pos', we can only change the first instance of 'ps' to something else, or ALL instnces of 'ps' to something else, including those in e.g. "ops", etc.? Boundary mode doesn't seem to work when there's an underscore before the selection? E.g. 'ps' vs '_ps'.

-- [ ] You know it would be cool if the VISREP command area just worked like Neovim. I.e. modal editing in there.
-- [ ] TODO Ensure that the first item in the [N/N] list is the one we started with, not the literal first.
-- [ ] TODO Config: Add standard plugin configuration options.
-- [ ] TODO Config: default mode. Add `vim.g.visrep_default_mode = 'boundary'|'anywhere'`.
-- [ ] TODO Config: preview scope. Add `vim.g.visrep_preview = 'viewport'|'global'|'auto'` and `vim.g.visrep_preview_margin = 10` (extra lines above/below viewport).
-- [ ] TODO Theming: expose highlight groups (e.g. VisrepText) as user-configurable.
-- [ ] TODO Debounce: Coalesce rapid keystrokes with ~10–20ms debounce for rerender.
-- [ ] TODO Async index: Implement async build for very large files (>100k lines)?
-- [ ] TODO Unicode boundaries: Use 'iskeyword' or Vim regex classes to widen beyond ASCII.
-- [ ] TODO Multi-line live preview: Extend overlay builder to selections with newlines.
-- [ ] TODO Incremental viewport updates: Diff previous/next visible ranges; update only changed lines.
-- [ ] TODO Case behavior: Option to toggle case sensitivity (e.g. smartcase) per invocation.

-- [?] How should we handle situations where the user wants to replace something with *nothing*?
-- [?] What are the biggest pain points of the default %s search and replace that you're trying to remedy here?



_G.Visrep = function()
    local cursor_pos = vim.fn.getpos('.')
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local selected_text = vim.fn.getline(start_pos[2], end_pos[2])
    local pattern = ''
    local new_string = ''

    -- Concatenate selected lines into a single string
    for i, line in ipairs(selected_text) do
        if i > 1 then
            pattern = pattern .. '\n'
        end
        local start_col = (i == 1) and start_pos[3] or 1
        local end_col = (i == #selected_text) and end_pos[3] or #line
        pattern = pattern .. line:sub(start_col, end_col)
    end

    -- Interactive input + preview (single-line selections only). For multi-line
    -- selections we fall back to a simple input prompt later.

    -- Decide whether to enforce word boundaries.
    -- Only apply when the selection is a single line and looks like a keyword.
    local is_single_line = not pattern:find('\n', 1, true)
    local is_wordlike = is_single_line and (pattern:match('^[%w_]+$') ~= nil)

    -- Build literal core as sequence of byte matches for robustness.
    local core = {}
    for i = 1, #pattern do
        core[#core+1] = string.format('\\%%x%02X', pattern:byte(i))
    end
    local literal_core = table.concat(core)

    local pattern_any   = '\\V' .. literal_core
    local pattern_word  = is_wordlike and ('\\V\\<' .. literal_core .. '\\>') or nil

    -- Interactive preview: highlight matches and overlay the replacement as
    -- you type. Toggle boundary/anywhere with <Tab>, apply on <Enter>, cancel on <Esc>.
    local mode = (pattern_word and 'boundary') or 'anywhere'

    local function is_word_char_byte(b)
        if not b then return false end
        return (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b == 95) or (b >= 97 and b <= 122)
    end

    local function push_merged(list, col0, col1)
        local n = #list
        if n == 0 or col0 > list[n].col1 then
            list[n + 1] = { col0 = col0, col1 = col1 }
        else
            if col1 > list[n].col1 then list[n].col1 = col1 end
        end
    end

    local function build_match_index(bufnr, literal, sel_lnum, sel_col0, sel_col1)
        local lc = vim.api.nvim_buf_line_count(bufnr)
        local by_any = {}
        local by_bnd = {}
        local nav_any = {}
        local nav_bnd = {}
        if #literal > 0 then
            for lnum = 0, lc - 1 do
                local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ''
                local init = 1
                local list_any = nil
                local list_bnd = nil
                while true do
                    local s, e = string.find(line, literal, init, true)
                    if not s then break end
                    local c0, c1 = s - 1, e
                    -- anywhere list
                    list_any = list_any or {}
                    push_merged(list_any, c0, c1)
                    nav_any[#nav_any + 1] = { lnum = lnum, col0 = c0, col1 = c1 }
                    -- boundary list
                    local prev = (s > 1) and string.byte(line, s - 1) or nil
                    local nextb = (e < #line) and string.byte(line, e + 1) or nil
                    if not is_word_char_byte(prev) and not is_word_char_byte(nextb) then
                        list_bnd = list_bnd or {}
                        push_merged(list_bnd, c0, c1)
                        nav_bnd[#nav_bnd + 1] = { lnum = lnum, col0 = c0, col1 = c1 }
                    end
                    init = e + 1
                end
                if list_any then by_any[lnum] = list_any end
                if list_bnd then by_bnd[lnum] = list_bnd end
            end
        end
        -- ensure selection present in both maps and nav lists
        local function ensure(listmap, navlist)
            local exists = false
            local t = listmap[sel_lnum]
            if t then
                for _, iv in ipairs(t) do
                    if iv.col0 == sel_col0 and iv.col1 == sel_col1 then exists = true; break end
                end
            end
            if not exists then
                if not t then t = {}; listmap[sel_lnum] = t end
                push_merged(t, sel_col0, sel_col1)
                navlist[#navlist + 1] = { lnum = sel_lnum, col0 = sel_col0, col1 = sel_col1 }
            end
        end
        ensure(by_any, nav_any)
        ensure(by_bnd, nav_bnd)
        return by_any, by_bnd, nav_any, nav_bnd
    end

    local ns = vim.api.nvim_create_namespace('VisrepPreview')
    local function clear_ns(bufnr)
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end

    -- lazy init highlight groups
    pcall(vim.api.nvim_set_hl, 0, 'VisrepText',  { link = 'IncSearch' })

    local bufnr = vim.api.nvim_get_current_buf()
    local literal = pattern
    local cur_idx = nil
    local by_line_any, by_line_bnd, nav_any, nav_bnd = build_match_index(bufnr, literal, start_pos[2]-1, start_pos[3]-1, end_pos[3])
    local active_by_line = nil
    local nav_targets = nil

    local function jump_to(step)
        if #nav_targets == 0 then return end
        if not cur_idx then
            cur_idx = (step >= 0) and 1 or #nav_targets
        else
            cur_idx = ((cur_idx - 1 + step) % #nav_targets) + 1
        end
        local m = nav_targets[cur_idx]
        if m then
            vim.api.nvim_win_set_cursor(0, { m.lnum + 1, m.col0 })
            pcall(function() vim.cmd('normal! zvzz') end)
        end
        return cur_idx
    end

    local function update_prompt(repl)
        local cnt_total = #nav_targets
        local idx = cur_idx or (cnt_total > 0 and 1 or 0)
        local label = (mode == 'boundary') and 'boundary' or 'anywhere'
        local shown = literal
        if #shown > 30 then shown = shown:sub(1, 27) .. '…' end
        local prompt = string.format('[%d/%d] Replace "%s" %s with: %s', idx, cnt_total, shown, label, repl or '')
        vim.api.nvim_echo({{prompt, 'Normal'}}, false, {})
        vim.cmd('redraw')
    end

    local function rerender(repl)
        clear_ns(bufnr)
        local prev_idx = cur_idx
        -- Select active line-index and nav list by mode
        active_by_line = (mode == 'boundary') and by_line_bnd or by_line_any
        nav_targets    = (mode == 'boundary') and nav_bnd     or nav_any

        -- For visible range only, overlay the full preview line using virt_text segments
        local v_s = vim.fn.line('w0') - 1
        local v_e = vim.fn.line('w$') - 1
        for lnum = v_s, v_e do
            local list = active_by_line[lnum]
            if list then
            local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum+1, false)[1] or ''
            local segs = {}
            local idx = 0 -- 0-based consumed end
            for _, mm in ipairs(list) do
                -- prefix text
                local pre = line:sub(idx + 1, mm.col0)
                if #pre > 0 then segs[#segs+1] = { pre, 'Normal' } end
                -- replacement
                if repl and repl ~= '' then
                    segs[#segs+1] = { repl, 'VisrepText' }
                end
                idx = mm.col1
            end
            -- tail
            local tail = line:sub(idx + 1)
            if #tail > 0 then segs[#segs+1] = { tail, 'Normal' } end

            -- If no repl text (empty), segs may be only pre+tail which is fine
            if #segs > 0 then
                vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
                    virt_text = segs,
                    virt_text_win_col = 0,
                    virt_text_pos = 'overlay',
                    priority = 210,
                })
            end
            end
        end

        -- choose current index: keep previous if possible, else prefer selection, else 1
        if #nav_targets == 0 then
            cur_idx = nil
        else
            if prev_idx and prev_idx >= 1 and prev_idx <= #nav_targets then
                cur_idx = prev_idx
            else
                -- prefer selection index if present
                local sel_index = nil
                for i, t in ipairs(nav_targets) do
                    if t.lnum == (start_pos[2]-1) and t.col0 == (start_pos[3]-1) and t.col1 == end_pos[3] then
                        sel_index = i; break
                    end
                end
                cur_idx = sel_index or 1
            end
        end

        update_prompt(repl)
    end

    if is_single_line then
        local input = ''
        rerender(input)
        while true do
            local key = vim.fn.getchar()
            if type(key) == 'number' then
                local as_char = vim.fn.nr2char(key)
                local trans_num = as_char and vim.fn.keytrans(as_char) or ''
                local trans_num_l = string.lower(trans_num or '')
                if key == 9 or trans_num_l == '<tab>' then -- Tab
                    if pattern_word then
                        mode = (mode == 'boundary') and 'anywhere' or 'boundary'
                    end
                    rerender(input)
                elseif key == 13 or key == 10 or trans_num_l == '<cr>' then -- Enter
                    clear_ns(bufnr)
                    new_string = input
                    break
                elseif key == 27 or trans_num_l == '<esc>' then -- Esc
                    clear_ns(bufnr)
                    vim.fn.setpos('.', cursor_pos)
                    return
                elseif key == 8 or key == 127 or trans_num_l == '<bs>' or trans_num_l == '<c-h>' then -- Backspace
                    input = input:sub(1, math.max(0, #input - 1))
                    rerender(input)
                elseif key == 14 or trans_num_l == '<c-n>' or trans_num == '^N' then -- Ctrl-N
                    jump_to(1)
                    rerender(input)
                elseif key == 16 or trans_num_l == '<c-p>' or trans_num == '^P' then -- Ctrl-P
                    jump_to(-1)
                    rerender(input)
                else
                    local ch = as_char
                    if ch and ch ~= '' then
                        input = input .. ch
                        rerender(input)
                    end
                end
            else
                -- Special key sequence as string; normalize with keytrans
                local trans = vim.fn.keytrans(key)
                local tl = string.lower(trans)
                if tl == '<tab>' then
                    if pattern_word then
                        mode = (mode == 'boundary') and 'anywhere' or 'boundary'
                    end
                    rerender(input)
                elseif tl == '<cr>' then
                    clear_ns(bufnr)
                    new_string = input
                    break
                elseif tl == '<esc>' then
                    clear_ns(bufnr)
                    vim.fn.setpos('.', cursor_pos)
                    return
                elseif tl == '<bs>' or tl == '<c-h>' then
                    input = input:sub(1, math.max(0, #input - 1))
                    rerender(input)
                elseif tl == '<c-n>' or trans == '^N' then
                    jump_to(1)
                    rerender(input)
                elseif tl == '<c-p>' or trans == '^P' then
                    jump_to(-1)
                    rerender(input)
                else
                    -- ignore other specials
                end
            end
        end
    else
        -- Multi-line selection: simpler prompt with no live preview
        new_string = vim.fn.input(string.format('Replace "%s" with: ', pattern))
        if new_string == '' then return end
    end

    -- Pick a separator that is not in pattern or new_string
    local separators = { '/', '#', '%', '!', '@', '$', '^', '&', '*', '+', '=', '?', '|', '~' }
    local sep = nil
    for _, s in ipairs(separators) do
        if not pattern:find(s, 1, true) and not new_string:find(s, 1, true) then
            sep = s
            break
        end
    end
    if not sep then
        print('Visrep: could not find a suitable separator.')
        return
    end

    local regex_specials = '().%+-*?[]^$\\|/'
    local escaped_new_string = vim.fn.escape(new_string, sep .. '\\' .. regex_specials)

    -- Choose the active pattern based on preview mode.
    local active_pattern = (mode == 'boundary') and (pattern_word or pattern_any) or pattern_any

    -- Perform the substitution globally; add 'e' to suppress errors when not found.
    local bufnr = vim.api.nvim_get_current_buf()
    local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)
    pcall(vim.cmd, ':%s' .. sep .. active_pattern .. sep .. escaped_new_string .. sep .. 'ge')

    local after_tick = vim.api.nvim_buf_get_changedtick(bufnr)
    if after_tick == before_tick then
        -- No global matches: replace the originally selected region only.
        local srow = start_pos[2] - 1
        local erow = end_pos[2] - 1

        local lines = vim.api.nvim_buf_get_lines(bufnr, srow, erow + 1, false)
        if #lines == 0 then
            vim.fn.setpos('.', cursor_pos)
            return
        end

        local first_line = lines[1]
        local last_line  = lines[#lines]

        local start_col1 = start_pos[3] -- 1-based inclusive
        local end_col1   = end_pos[3]   -- 1-based inclusive (may be huge for linewise)

        -- Clamp end column for safety
        if erow == srow then
            if end_col1 > #first_line then end_col1 = #first_line end
        else
            if end_col1 > #last_line then end_col1 = #last_line end
        end

        local prefix = first_line:sub(1, start_col1 - 1)
        local suffix = last_line:sub(end_col1 + 1)

        local rep_lines = vim.split(new_string, "\n", true)

        local new_lines
        if srow == erow then
            if #rep_lines <= 1 then
                new_lines = { prefix .. new_string .. suffix }
            else
                new_lines = {}
                new_lines[1] = prefix .. rep_lines[1]
                for i = 2, #rep_lines - 1 do new_lines[#new_lines + 1] = rep_lines[i] end
                new_lines[#new_lines + 1] = rep_lines[#rep_lines] .. suffix
            end
        else
            if #rep_lines <= 1 then
                new_lines = { prefix .. new_string .. suffix }
            else
                new_lines = {}
                new_lines[1] = prefix .. rep_lines[1]
                for i = 2, #rep_lines - 1 do new_lines[#new_lines + 1] = rep_lines[i] end
                new_lines[#new_lines + 1] = rep_lines[#rep_lines] .. suffix
            end
        end

        vim.api.nvim_buf_set_lines(bufnr, srow, erow + 1, false, new_lines)
    end

    -- Restore the cursor position
    vim.fn.setpos('.', cursor_pos)
end

-- -----------------------------------------------------------------------------

-- Slect 0.1.0
-- Draw virtual text over selected text or at the cursor position.

-- local ns_id = vim.api.nvim_create_namespace("SlectNamespace")
--
-- _G.Slect = function()
--   print("Slect called")
--
--   local bufnr = vim.api.nvim_get_current_buf()
--   local cursor_pos = vim.api.nvim_win_get_cursor(0)
--   local line, col = cursor_pos[1] - 1, cursor_pos[2]
--   local virtual_text = ""
--   local extmark_id
--
--   local function update_virtual_text(text)
--     print("Updating virtual text")
--     vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
--     extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, col, {
--       virt_text = {{text, "Comment"}},
--       virt_text_win_col = col,
--       hl_mode = "combine",
--     })
--     vim.api.nvim_win_set_cursor(0, cursor_pos)
--     vim.api.nvim_command("redraw")
--   end
--
--   while true do
--     local key = vim.fn.getchar()
--     local c = vim.fn.nr2char(key)
--     print("Key pressed: " .. c)
--
--     if c == "\r" then
--       vim.api.nvim_buf_del_extmark(bufnr, ns_id, extmark_id)
--       break
--     elseif c == "\27" then  -- Esc key
--       update_virtual_text("")
--       vim.api.nvim_buf_del_extmark(bufnr, ns_id, extmark_id)
--       break
--     else
--       virtual_text = virtual_text .. c
--       update_virtual_text(virtual_text)
--     end
--   end
-- end

-- -----------------------------------------------------------------------------

-- SLECT 0.2.0
-- The idea here was to play around with idea for a Neovim paintbrush. I.e. Move
-- a virtual cursor around the screen and add text to the buffer.

-- local api = vim.api
-- local ns_id = api.nvim_create_namespace('Slect')
--
-- local function validate_cursor(buf, cursor)
--     local line_count = api.nvim_buf_line_count(buf)
--     local max_col = api.nvim_buf_get_lines(buf, cursor[1], cursor[1]+1, false)[1]:len()
--     cursor[1] = math.max(0, math.min(line_count - 1, cursor[1]))
--     cursor[2] = math.max(0, math.min(max_col, cursor[2]))
--     return cursor
-- end
--
-- local function update_virtual_text(buf, virtual_cursor, vcursor_id)
--     -- Update the extmark to the new position
--     print("Updating text:", virtual_cursor, vcursor_id)
--     api.nvim_buf_set_extmark(buf, ns_id, virtual_cursor[1], virtual_cursor[2], {
--         virt_text = {{"|", "Comment"}},
--         -- Make it right-aligned so it behaves more like a cursor
--         virt_text_pos = "overlay",
--         id = vcursor_id
--     })
-- end
--
-- _G.Slect = function()
--     local buf = api.nvim_get_current_buf()
--     print("Buffer:", buf)
--     local win = api.nvim_get_current_win()
--
--     local cursor = api.nvim_win_get_cursor(win)
--     local virtual_cursor = {cursor[1] - 1, cursor[2]} -- 0-based indexing
--
--     -- Set the initial virtual cursor and save its ID
--     local vcursor_id = api.nvim_buf_set_extmark(buf, ns_id, virtual_cursor[1], virtual_cursor[2], {
--         virt_text = {{"x", "Search"}},
--         -- Make it right-aligned so it behaves more like a cursor
--         virt_text_pos = "overlay",
--     })
--
--     local function on_input(key)
--         virtual_cursor = validate_cursor(buf, virtual_cursor)
--         if key == 'j' then
--             virtual_cursor[1] = virtual_cursor[1] + 1
--         elseif key == 'k' then
--             virtual_cursor[1] = virtual_cursor[1] - 1
--         elseif key == 'h' then
--             virtual_cursor[2] = virtual_cursor[2] - 1
--         elseif key == 'l' then
--             virtual_cursor[2] = virtual_cursor[2] + 1
--         else
--             return true
--         end
--         -- Update the virtual cursor's position
--         update_virtual_text(buf, virtual_cursor, vcursor_id)
--         vim.cmd("redraw")
--         return false
--     end
--     local success = vim.fn.input({prompt = '', func = 'v:lua.Slect_on_input', cancelreturn = ''})
--     api.nvim_buf_del_extmark(buf, ns_id, vcursor_id)
--     api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
-- end
--
-- function _G.Slect_on_input(key)
--   return on_input(key)
-- end

--------------------------------------------------------------------------------

-- Function to auto-close HTML tags
-- Doesn't work.
-- _G.auto_close_tags = function()
--     local bufnr = vim.api.nvim_get_current_buf()
--     local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
--
--     for i, line in ipairs(lines) do
--         -- This simple pattern matches tags that might require self-closing
--         -- Note: Lua patterns do not support lookbehind; thus, the solution is basic
--         local modifiedLine = line:gsub("(<(%w+)[^>/]*)>", function(tagStart)
--             local voidElements = "area|base|br|col|command|embed|hr|img|input|keygen|link|meta|param|source|track|wbr"
--             if tagStart:match(voidElements) then
--                 return tagStart .. " />"
--             else
--                 return tagStart .. ">"
--             end
--         end)
--
--         if modifiedLine ~= line then
--             vim.api.nvim_buf_set_lines(bufnr, i-1, i, false, {modifiedLine})
--         end
--     end
-- end

-- DO NOT EDIT:

-- I think this was something to do with the accelerate_jk plugin.

-- function M.generate_series(type, n, factor)
--     local series = {}
--     if type == "quadratic" then
--         for i = 1, n do
--             table.insert(series, i * i * factor)
--         end
--     elseif type == "cubic" then
--         for i = 1, n do
--             table.insert(series, i * i * i * factor)
--         end
--     end
--     return series
-- end
--
-- local acceleration_table = M.generate_series("quadratic", 4, 5)
-- local deceleration_table = {}
--
-- local deceleration_intervals = {200, 300}
-- for _, interval in ipairs(deceleration_intervals) do
--     local deceleration_steps = M.generate_series("quadratic", 2, 3)
--     table.insert(deceleration_table, {interval, deceleration_steps})
-- end
--
-- print("Acceleration Table: ")
-- for _, value in ipairs(acceleration_table) do
--     print(value)
-- end
--
-- print("\nDeceleration Table: ")
-- for _, pair in ipairs(deceleration_table) do
--     print(pair[1], table.concat(pair[2], ", "))
-- end

-- Picture in Picture plugin?
-- [ ] Could this be pegged to a certain part of the file even while scrolling?
-- [ ] Could this be used to do the one line scrolling thing?
-- M.Border = vim.api.nvim_open_win(0, true, {relative='win', width=vim.api.nvim_win_get_width(0), height=3, bufpos=vim.api.nvim_win_get_cursor(), border = "none" })
-- vim.api.nvim_open_win(0, true, {relative='win', width=vim.api.nvim_win_get_width(0), height=3, bufpos=vim.api.nvim_win_get_cursor(), border = "none" })

-- ========================================================================== --
-- Source Plugins
-- ========================================================================== --

-- local installed_plugins = {
--     -- ["lukas-reineke/indent-blankline.nvim"] = "lukas-reineke/indent-blankline.nvim",
--     -- ["lukas-reineke/indent-blankline.nvim"] = "indent-blankline",
-- }
--
-- local function case_insensitive_compare(str1, str2)
--     return str1:lower() == str2:lower()
-- end
--
-- function M.PopulateInstalledPlugins()
--     local plug_dirs = vim.fn.globpath("C:/Users/Christopher/.config/nvim/plugs", "*", true, true)
--     for _, dir in ipairs(plug_dirs) do
--         local plugin_name = vim.fn.fnamemodify(dir, ":t")
--         installed_plugins[plugin_name] = dir
--     end
-- end
--
-- function M.PrintInstalledPlugins()
--     for plugin_name, plugin_path in pairs(installed_plugins) do
--         print(plugin_name .. " => " .. plugin_path)
--     end
-- end
--
-- function M.SourcePlugin(plugin_name)
--     plugin_name = plugin_name:gsub("^%s*(.-)%s*$", "%1") -- Trim leading/trailing spaces
--     for installed_plugin_name, plugin_path in pairs(installed_plugins) do
--         if case_insensitive_compare(installed_plugin_name, plugin_name) then
--             local sourced = pcall(dofile, plugin_path)
--             if sourced then
--                 print("Sourced " .. plugin_name)
--             else
--                 print("Failed to source " .. plugin_name)
--             end
--             return
--         end
--     end
--     print(plugin_name .. " not found.")
-- end
--
-- function M.PromptAndSourcePlugin()
--     local plugin_name = vim.fn.input("input", "Enter plugin name: ")
--     SourcePlugin(plugin_name)
-- end
--
-- function M.SetPluginSourcingKeybinding()
--     vim.api.nvim_set_keymap("n", "<leader>z", ":SourcePlugin<CR>", {noremap = true, silent = false})
-- end
--
-- vim.cmd("command! SourcePlugin lua PromptAndSourcePlugin()")

-- Call this in init.lua or plugins.lua.
-- PopulateInstalledPlugins()

-- ========================================================================== --
-- Keybinding Helpers
-- ========================================================================== --

-- function M.Map(mode, new, old, opts)
--     -- map("n", ";f", ":Telescope find_files<CR>", {expr = true})
--     local default_opts = {}
--     if opts then
--         options = vim.tbl_extend("force", default_opts, opts) -- Merges the `default_opts` and `opts` tables
--     end
--     vim.api.nvim_set_keymap(mode, new, old, options)
-- end

-- function M.Insert(new, old)
--     vim.api.nvim_set_keymap('i', new, old, {noremap=true, silent=true})
-- end

-- function M.Normal(new, old)
--     vim.api.nvim_set_keymap('n', new, old, {noremap=true, silent=true})
-- end

-- function M.Visual(new, old)
--     vim.api.nvim_set_keymap('v', new, old, {noremap=true, silent=true})
-- end

-- function M.Terminal(new, old)
--     vim.api.nvim_set_keymap('t', new, old, {buffer = 0})
-- end

-- ========================================================================== --
-- Language Helpers
-- ========================================================================== --

-- Odin
-- -------------------------------------------------------------------------- --

-- Run `orf $file` from within Neovim and display the output in a split window.

-- function orf()
--     local output = vim.fn.systemlist('orf ' .. vim.fn.expand('%'))
--     local bufnr = vim.api.nvim_create_buf(false, true)
--     vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
--     vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
--     vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
--     vim.api.nvim_buf_set_option(bufnr, 'filetype', 'odin')
--     vim.api.nvim_buf_set_option(bufnr, 'syntax', 'odin')
--     vim.api.nvim_buf_set_option(bufnr, 'modifiable', false) -- Make buffer read-only
--     -- vim.cmd('vnew')
--     vim.cmd('split')
--     vim.api.nvim_win_set_buf(0, bufnr)
--     vim.api.nvim_win_set_option(0, 'wrap', false)
--     vim.api.nvim_win_set_height(0, 10)
--     vim.cmd('normal! gg')
--     vim.cmd('redraw')
-- end

-- This is an experiment in creating a code compilation watch window in Lua for Neovim.

-- function bsop(buffer, name, value)
--     vim.api.nvim_buf_set_option(buffer, name, value)
-- end
--
-- local bufnr = nil
-- function on_save()
--     local filepath = vim.fn.expand('%:p:h')
--     local tempdir = filepath .. '/temp'
--     if not vim.fn.isdirectory(tempdir) then
--         os.execute("mkdir " .. tempdir)
--         -- vim.fn.mkdir(tempdir)
--     end
--     local timestamp = os.time(os.date("!*t"))
--     local tempname = tempdir .. '/' .. vim.fn.expand('%:t:r') .. '_temp_' .. timestamp .. '.odin'
--     vim.api.nvim_command('silent w! ' .. tempname)
--     local output = vim.fn.systemlist('odin run ' .. tempname .. ' -file')
--     if not bufnr then
--         bufnr = vim.api.nvim_create_buf(false, true)
--         vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
--         vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
--         vim.api.nvim_buf_set_option(bufnr, 'filetype', 'odin')
--         vim.api.nvim_buf_set_option(bufnr, 'syntax', 'odin')
--         vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
--         vim.cmd('split')
--         local winid = vim.fn.win_getid()
--         vim.api.nvim_win_set_buf(winid,bufnr)
--         vim.api.nvim_win_set_option(winid,'wrap',true)
--         vim.api.nvim_win_set_height(winid,10)
--     end
--     local current_win = vim.fn.win_getid()
--     local winids = vim.fn.win_findbuf(bufnr)
--     for _, winid in ipairs(winids) do
--         if winid ~= current_win then
--             pcall(vim.api.nvim_buf_set_option,bufnr,'modifiable',true)
--             pcall(vim.api.nvim_win_call,
--             winid,
--             function()
--                 pcall(vim.api.nvim_buf_set_lines,bufnr,0,-1,false,output)
--             end)
--             pcall(vim.api.nvim_buf_set_option,bufnr,'modifiable',false)
--         end
--     end
-- end
-- function odin_live()
--     vim.cmd('autocmd BufWritePost <buffer> lua on_save()')
-- end

-- local bufnr = nil
-- function on_save()
--     -- Create temporary file with same content as current buffer
--     local filepath = vim.fn.expand('%:p:h')
--     local tempdir = filepath .. '/temp'
--     if not vim.fn.isdirectory(tempdir) then
--         vim.fn.mkdir(tempdir)
--     end
--     local tempname = tempdir .. '/' .. vim.fn.expand('%:t') .. '.tmp'
--     vim.api.nvim_command('silent w! ' .. tempname)
--
--     -- Run odin command on temporary file
--     local output = vim.fn.systemlist('odin run ' .. tempname .. ' -file')
--
--     if not bufnr then
--         bufnr = vim.api.nvim_create_buf(false, true)
--         vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
--         vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
--         vim.api.nvim_buf_set_option(bufnr, 'filetype', 'odin')
--         vim.api.nvim_buf_set_option(bufnr, 'syntax', 'odin')
--         -- Make buffer read-only
--         vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
--         -- Open new split window and display buffer
--         -- vim.cmd('vnew')
--         vim.cmd('split')
--         local winid = vim.fn.win_getid()
--         vim.api.nvim_win_set_buf(winid,bufnr)
--         -- Set wrap property to true
--         vim.api.nvim_win_set_option(winid,'wrap',true)
--         -- Set window height to 10 lines
--         vim.api.nvim_win_set_height(winid,10)
--     end
--
--     -- Update buffer content in background without taking control away from cursor in main buffer
--     local current_win = vim.fn.win_getid()
--     local winids = vim.fn.win_findbuf(bufnr)
--     for _, winid in ipairs(winids) do
--       if winid ~= current_win then
--           -- Temporarily set modifiable to true to update buffer content
--           pcall(vim.api.nvim_buf_set_option,bufnr,'modifiable',true)
--           -- Update buffer content without moving cursor from main window
--           pcall(vim.api.nvim_win_call,
--             winid,
--             function()
--               pcall(vim.api.nvim_buf_set_lines,bufnr,0,-1,false,output)
--             end)
--           -- Set modifiable back to false after updating content
--           pcall(vim.api.nvim_buf_set_option,bufnr,'modifiable',false)
--       end
--     end
-- end

-- function odin_live()
--   -- Register autocommand to run on_save function when the current buffer is written
--   vim.cmd('autocmd BufWritePost <buffer> lua on_save()')
-- end

-- This is a temporary function for calling `ebert.bat` on the Eebs folder for ebook testing.

-- local M = {}
-- function M.Ebert()
--     local folder_name = vim.fn.input('Enter folder name: ')
--     if folder_name ~= '' then
--         local folder_path = "C:\\Users\\Christopher\\Projects\\Eebs\\" .. folder_name
--         local output = vim.fn.system('ebert.bat "' .. folder_path .. '"')
--         print(output)
--     end
-- end

-- ========================================================================== --
-- Misc.
-- ========================================================================== --

-- Get the Golden Ratio of the current window by passing in width or height
-- -------------------------------------------------------------------------- --

-- function M.PrintWidth()
--     local width = math.floor(vim.api.nvim_win_get_width(0) / ((1 + math.sqrt(5)) / 2 * 100))
--     local height = math.floor(vim.api.nvim_win_get_height(0) / ((1 + math.sqrt(5)) / 2 * 100))
--     return width, height
-- end

-- M.Width = math.floor(vim.api.nvim_win_get_width(0) / ((1 + math.sqrt(5)) / 2 * 100))
-- M.Height = math.floor(vim.api.nvim_win_get_height(0) / ((1 + math.sqrt(5)) / 2 * 100))

-- function M.Golden(dimension)
--   local win_height = vim.api.nvim_win_get_height(0)
--   local win_width = vim.api.nvim_win_get_width(0)
--   local golden_ratio = (1 + math.sqrt(5)) / 2
--   local value
--   if dimension == "height" then
--     value = math.floor(win_width / golden_ratio)
--   elseif dimension == "width" then
--     value = math.floor(win_height * golden_ratio)
--   else
--     error("Invalid dimension. Must be 'height' or 'width'")
--   end
--   if value > win_height and dimension == "height" then
--     value = win_height
--   elseif value > win_width and dimension == "width" then
--     value = win_width
--   end
--   return value
-- end

-- Reload Lua Packages
-- ------------------------------------------------------------------------- --

-- TODO
-- function _G.ReloadConfig()
--     for name, _ in pairs(package.loaded) do
--         -- If the name of the module starts with 'lua' then remove the module
--         -- from the package.loaded table
--         -- TODO: Not sure this'll work for lua folder itself.
--         if name:match('^lua') then
--             package.loaded[name] = nil
--         end
--     end
--     dofile(vim.env.MYVIMRC)
-- end

-- ========================================================================== --
-- Plugins
-- ========================================================================== --

-- -------------------------------------------------------------------------- --
-- Lualine
-- -------------------------------------------------------------------------- --

-- Trigger re-render of status line every second.
-- -------------------------------------------------------------------------- --

-- NOTE Was this related to including a clock in the statusline?

-- function M.rerender_lualine()
--     if _G.Statusline_timer == nil then
--         _G.Statusline_timer = vim.loop.new_timer()
--     else
--         _G.Statusline_timer:stop()
--         vim.api.nvim_command("echo 'Statusline timer stopped.'")
--     end
--     -- Redraws *all* statuslines and window bars if "!" is included after `redrawstatus`.
--     _G.Statusline_timer:start(0, 1000, vim.schedule_wrap(function() vim.api.nvim_command("redrawstatus!") end))
--     vim.api.nvim_command("echo 'Statusline timer started.'")
-- end

-- Get inactive buffer numbers
-- -------------------------------------------------------------------------- --

-- TODO: Find a way to keep track of non-file buffers (autocomplete) and
-- make sure they don't show up in your custom buffer thing.
-- function M.get_inactive_buffer_numbers()
--     inactive_buffer_numbers = {}
--     for i, buffer in ipairs(vim.api.nvim_list_bufs()) do
--         buffer_number = vim.fn.bufnr(buffer)
--         buffer_name = vim.fn.bufname(buffer)
--         if buffer_number ~= vim.fn.bufnr('%') then
--             if buffer_name:match("^\\[\"#]") or buffer_name:match("^\\[No Name\\]") then
--                 goto continue
--             elseif buffer_name:match("NvimTree_%d") then
--                 table.insert(inactive_buffer_numbers, "꜏")
--             elseif vim.api.nvim_buf_get_var(buffer_number, "changedtick") == vim.fn.changetick() then
--                 table.insert(inactive_buffer_numbers, buffer_number)
--             -- else
--                 -- table.insert(inactive_buffer_numbers, buffer_number)
--             end
--         end
--         ::continue::
--     end
--     inactive_buffer_output = table.concat(inactive_buffer_numbers, ' ')
--     return string.format("%s", inactive_buffer_output)
-- end

-- Get active buffer number
-- -------------------------------------------------------------------------- --

-- function M.get_active_buffer_number()
--     active_buffer = ""
--     for i, buffer in ipairs(vim.api.nvim_list_bufs()) do
--         buffer_number = vim.fn.bufnr(buffer)
--         buffer_name = vim.fn.bufname(buffer)
--         if buffer_number == vim.fn.bufnr('%') then
--             if buffer_name:match("NvimTree_%d") then
--                 active_buffer = "꜏"
--             else
--                 active_buffer = buffer_number
--             end
--             -- active_buffer = buffer_number
--         end
--     end
--     return string.format("%s", active_buffer)
-- end

-- Key testing function to diagnose terminal key sequences
-- -------------------------------------------------------------------------- --

-- function _G.TestKey()
--     print("Press a key combination (or 'q' to quit):")
--     local key = vim.fn.getchar()
--     if type(key) == "number" then
--         local char = vim.fn.nr2char(key)
--         print(string.format("Received: char='%s', code=%d (0x%X)", char, key, key))
--     else
--         print(string.format("Received: %s", vim.inspect(key)))
--     end
--     if key ~= 113 then -- 'q' = 113
--         _G.TestKey()
--     end
-- end

return M
