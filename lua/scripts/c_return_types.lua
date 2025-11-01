if vim.g.vscode then
    return
end

local M = {}

local MAX_CONCURRENT_HOVERS = 6

local c_return_retries = {} ---@type table<integer,integer>
local c_return_parsers = {} ---@type table<integer,any>
local c_return_changedtick = {} ---@type table<integer,integer>
local c_return_states = {} ---@type table<integer, table>
local c_return_queries = {} ---@type table<string, any>
local c_return_marks = {} ---@type table<integer, table<integer, table>>

local namespace = vim.api.nvim_create_namespace("c_return_types")
local augroup = nil

local function apply_highlight()
    vim.api.nvim_set_hl(0, "CReturnType", { fg = "#808080" })
end

local function extract_hover_text(res)
    if not res then
        return nil
    end
    local contents = res.contents
    if not contents then
        return nil
    end
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

local function show()
    local ft = vim.bo.filetype
    if ft ~= "c" and ft ~= "cpp" and ft ~= "h" then
        return
    end

    pcall(function()
        local ih = vim.lsp.inlay_hint
        if ih and type(ih.enable) == "function" then
            local buf = vim.api.nvim_get_current_buf()
            local ok = pcall(ih.enable, buf, false)
            if not ok then
                pcall(ih.enable, false, buf)
            end
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
                local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, namespace, info.id, {})
                if pos and pos[1] then
                    new_row = pos[1]
                    info.virt_col = pos[2] or info.virt_col
                else
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

    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if #clients == 0 then
        c_return_changedtick[bufnr] = nil
        return
    end

    local client = nil
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

    local parser = c_return_parsers[bufnr]
    if not parser then
        local lang = ft
        if ft == "h" then
            lang = "c"
        end

        local ok
        ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
        if not ok and ft == "h" then
            ok, parser = pcall(vim.treesitter.get_parser, bufnr, "cpp")
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

    local lang = ft == "h" and "c" or ft
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
                vim.api.nvim_buf_del_extmark(bufnr, namespace, info.id)
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
                existing.id = vim.api.nvim_buf_set_extmark(bufnr, namespace, end_row, virt_col, opts)
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
                    vim.api.nvim_buf_del_extmark(bufnr, namespace, info.id)
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
                        show()
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

            state_ref.client.request("textDocument/hover", params, function(err, result)
                state_ref.active = state_ref.active - 1

                if c_return_states[bufnr] ~= state_ref then
                    return
                end

                local row, col = clamp_position(bufnr, item.end_row, item.virt_col)
                if not row then
                    local stale = mark_tbl[item.end_row]
                    if stale and stale.id then
                        vim.api.nvim_buf_del_extmark(bufnr, namespace, stale.id)
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
                        vim.api.nvim_buf_del_extmark(bufnr, namespace, current_mark.id)
                    end

                    local id = vim.api.nvim_buf_set_extmark(bufnr, namespace, row, col, opts)
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
                        vim.api.nvim_buf_del_extmark(bufnr, namespace, current_mark.id)
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

local function setup_autocmds()
    if augroup then
        return
    end

    augroup = vim.api.nvim_create_augroup("CReturnTypeHelper", { clear = true })

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave", "TextChanged" }, {
        group = augroup,
        pattern = { "*.c", "*.h", "*.cpp", "*.cc", "*.cxx", "*.hpp" },
        callback = function()
            show()
        end,
    })

    vim.api.nvim_create_autocmd("VimEnter", {
        group = augroup,
        callback = function()
            local ft = vim.bo.filetype
            if ft == "c" or ft == "cpp" or ft == "h" then
                vim.defer_fn(function()
                    show()
                end, 500)
            end
        end,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
        group = augroup,
        callback = function(args)
            local bufnr = args.buf
            local ft = vim.bo[bufnr].filetype
            if ft == "c" or ft == "cpp" or ft == "h" then
                vim.defer_fn(function()
                    show()
                end, 100)
            end
        end,
    })

    vim.api.nvim_create_autocmd("BufDelete", {
        group = augroup,
        callback = function(args)
            c_return_changedtick[args.buf] = nil
            c_return_retries[args.buf] = nil
            c_return_parsers[args.buf] = nil
            c_return_marks[args.buf] = nil
        end,
    })
end

function M.setup()
    if vim.g._crt_loaded then
        return M
    end
    vim.g._crt_loaded = true

    apply_highlight()

    local highlight_group = vim.api.nvim_create_augroup("CReturnTypeHighlight", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = highlight_group,
        callback = apply_highlight,
    })

    setup_autocmds()
    show()
    return M
end

M.show = show

-- [ ] TODO Extremely slow on big files; need lightweight toggle/disable path.

M.setup()

return M
