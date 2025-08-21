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

local c_return_hashes  = {} ---@type table<integer,string>  -- bufnr → sha256
local c_return_retries = {} ---@type table<integer,integer> -- bufnr → retry-count
local c_return_parsers = {} ---@type table<integer,any>     -- bufnr → parser cache
local c_return_changedtick = {} ---@type table<integer,integer> -- bufnr → changedtick

-- One namespace for all extmarks so we can clear/update them deterministically.
local c_return_ns = vim.api.nvim_create_namespace('c_return_types')

-- Track extmark ids we own per buffer so we can update/delete incrementally.
local c_return_marks = {} ---@type table<integer, table<integer, integer>> -- bufnr → { row → mark_id }

function M:show_c_return_types()
    -- Only process C/C++ files
    local ft = vim.bo.filetype
    if ft ~= 'c' and ft ~= 'cpp' and ft ~= 'h' then
        return
    end

    -- clangd (and some other servers) can show their own return-type inlay hints
    -- which would duplicate the helper text we are about to render.  Disable
    -- inlay hints for this buffer to avoid visual clutter.  (Neovim ≥0.10)
    pcall(function()
        local ih = vim.lsp.inlay_hint
        if ih and type(ih.enable) == 'function' then
            -- Signature (nvim 0.10): enable(buf, bool) or enable(bool, buf)
            local ok = pcall(ih.enable, vim.api.nvim_get_current_buf(), false)
            if not ok then pcall(ih.enable, false, vim.api.nvim_get_current_buf()) end
        end
    end)

    local bufnr = vim.api.nvim_get_current_buf()

    -- Early exit for empty buffers.
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if line_count == 0 or (line_count == 1 and vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == "") then
        return
    end

    -- Detect if the buffer has changed since last processing.
    local tick = vim.api.nvim_buf_get_changedtick(bufnr)

    -- Skip if content hasn't changed.
    if c_return_changedtick[bufnr] == tick then
        return
    end

    -- Prepare per-buffer mark table.
    local mark_tbl = c_return_marks[bufnr]
    if not mark_tbl then
        mark_tbl = {}
        c_return_marks[bufnr] = mark_tbl
    end

    -- Check if LSP is attached.
    local clients = vim.lsp.get_clients({bufnr = bufnr})
    if #clients == 0 then
        -- No LSP yet, so clear changedtick to force reprocess when LSP attaches.
        c_return_changedtick[bufnr] = nil
        return
    end

    -- Track if we found any return types.
    local found_any = false

    -- Get first client for position encoding
    local client = clients[1]
    
    -- Check if client supports hover method
    if not client:supports_method(vim.lsp.protocol.Methods.textDocument_hover) then
        -- Client doesn't support hover yet, clear changedtick to retry later
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
    local root = tree:root()

    -- Query for function calls
    local lang = ft == 'h' and 'c' or ft -- Use cached lang from parser
    local query_ok, query = pcall(vim.treesitter.query.parse, lang, [[
    (call_expression
    function: (identifier) @func
    ) @call
    ]])
    if not query_ok then
        return
    end

    -- Collect all function calls first for batch processing
    local function_calls = {} -- Array of {node, parent, start_row, start_col, end_row, end_col}
    local processed = {}

    for id, node in query:iter_captures(root, bufnr, 0, -1) do
        if query.captures[id] == "func" then
            local parent = node:parent()
            local end_row, end_col = parent:end_()

            -- Skip if already processed
            if not processed[end_row] then
                processed[end_row] = true
                local start_row, start_col = node:start()
                table.insert(function_calls, {
                    node = node,
                    parent = parent,
                    start_row = start_row,
                    start_col = start_col,
                    end_row = end_row,
                    end_col = end_col,
                    func_name = vim.treesitter.get_node_text(node, bufnr)
                })
            end
        end
    end

    -- Keep a set of rows we touched this pass to later delete stale marks.
    local seen_rows = {}

    -- Process all function calls
    for _, call_info in ipairs(function_calls) do
        local start_row = call_info.start_row
        local start_col = call_info.start_col
        local end_row = call_info.end_row
        local end_col = call_info.end_col

        -- Make LSP hover request with proper position encoding
        local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
        params.position.line = start_row
        params.position.character = start_col

        -- Use synchronous request to get immediate results
        local result = vim.lsp.buf_request_sync(bufnr, 'textDocument/hover', params, 500)

        if result then
            for _, res in pairs(result) do
                if res.result and res.result.contents then
                    local content = ""
                    if type(res.result.contents) == "string" then
                        content = res.result.contents
                    elseif res.result.contents.value then
                        content = res.result.contents.value
                    end

                    if content ~= "" then
                        -- Parse return type from clangd format: → `type`
                        local return_type = content:match("→%s*`([^`]+)`")

                        if return_type and return_type ~= "void" then
                            -- Simplify complex types
                            -- Remove "aka" information: "FILE * (aka struct _iobuf *)" -> "FILE*"
                            return_type = return_type:gsub("%s*%(aka[^)]+%)", "")
                            -- Keep array notation together: "char []" -> "char[]"
                            return_type = return_type:gsub("(%S)%s+(%[%])", "%1%2")
                            -- Remove extra spaces around pointers: "FILE *" -> "FILE*"
                            return_type = return_type:gsub("(%S)%s+%*", "%1*")
                            -- Clean up remaining whitespace
                            return_type = return_type:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

                            -- Check if there's a semicolon right after the function call
                            local line = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1]
                            local char_after = line:sub(end_col + 1, end_col + 1)

                            local virt_col = (char_after == ";") and (end_col + 1) or end_col

                            local opts = {
                                virt_text = {{" ← " .. return_type, "CReturnType"}},
                                virt_text_pos = "inline",
                                undo_restore = false,
                                invalidate = true,
                            }

                            -- Re-use existing mark on that row if present.
                            local prev_id = mark_tbl[end_row]
                            if prev_id then opts.id = prev_id end

                            local new_id = vim.api.nvim_buf_set_extmark(bufnr, c_return_ns, end_row, virt_col, opts)

                            mark_tbl[end_row] = new_id
                            seen_rows[end_row] = true
                            found_any = true
                        end
                    end
                    break -- Only process first LSP client result
                end
            end
        end
    end

    -- If we found any results, mark as processed
    if found_any then
        c_return_changedtick[bufnr] = tick
        c_return_retries[bufnr] = nil
    else
        -- No results found, maybe LSP isn't ready yet
        local retries = c_return_retries[bufnr] or 0
        if retries < 3 then
            -- Try again in a moment
            c_return_retries[bufnr] = retries + 1
            vim.defer_fn(function()
                if vim.api.nvim_buf_is_valid(bufnr) then
                    M:show_c_return_types()
                end
            end, 300 * (retries + 1))  -- Increasing delay: 300ms, 600ms, 900ms
        else
            -- Give up and mark as processed to avoid infinite retries
            c_return_changedtick[bufnr] = tick
            c_return_retries[bufnr] = nil
        end
    end

    -- Remove stale marks (function call deleted)
    for row, id in pairs(mark_tbl) do
        if not seen_rows[row] then
            vim.api.nvim_buf_del_extmark(bufnr, c_return_ns, id)
            mark_tbl[row] = nil
        end
    end
end

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

-- [ ] TODO We should add support for rewrapping multiple lines, where one or more
-- of the lines are already wrapped. E.g. if we have a selection of 4 lines,
-- where lines 1, 2, and 4 are already within the wrap boundary, but 3 has a
-- length longer than our wrap column, we should be able to reflow everything
-- below the offending line.

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

-- Replace visually selected text globally with a new string. Respects word
-- boundaries.

-- [!] TODO This still has issues with targetting words within other words. E.g.
-- when we select something like "my_word" and replace it with something else,
-- other variables that contain "my_word", like "my_words" or "my_word_var" will
-- have their instance of my_word replaced as well. This is because the pattern
-- is not actually word-boundary aware? We need to ensure that, at the very
-- least, we allow the user to make one replacement strategy the default, and
-- find some quick way to toggle between these modes. The best case here would
-- be that, after running the command, when we see the input prompt at the
-- bottom of the screen we let the user toggle modes with a keypress, e.g.
-- with the <Tab> key, or something like that. Not sure if this is feasible
-- in Neovim.

-- [ ] TODO I see room here for serious performance improvements.

_G.Visrep = function()
    local cursor_pos = vim.fn.getpos('.')
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local selected_text = vim.fn.getline(start_pos[2], end_pos[2])
    local pattern = ''

    -- Concatenate selected lines into a single string
    for i, line in ipairs(selected_text) do
        if i > 1 then
            pattern = pattern .. '\n'
        end
        local start_col = (i == 1) and start_pos[3] or 1
        local end_col = (i == #selected_text) and end_pos[3] or #line
        pattern = pattern .. line:sub(start_col, end_col)
    end

    -- Prompt for the replacement string
    local new_string = vim.fn.input('Replace "' .. pattern .. '" with: ')
    if new_string == "" then
        return
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
        print("Could not find a suitable separator for the pattern and replacement.")
        return
    end

    -- Convert the pattern to a sequence of byte matches
    -- \V makes the pattern very literal, and \%xXX matches a byte with hex code XX
    local final_pattern = '\\V'
    for i = 1, #pattern do
        final_pattern = final_pattern .. string.format("\\%%x%02X", pattern:byte(i))
    end

    local regex_specials = '().%+-*?[]^$\\|/'
    local escaped_new_string = vim.fn.escape(new_string, sep .. '\\' .. regex_specials)

    -- Perform the substitution globally
    vim.cmd(':%s' .. sep .. final_pattern .. sep .. escaped_new_string .. sep .. 'g')

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
