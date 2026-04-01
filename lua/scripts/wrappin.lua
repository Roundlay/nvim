if vim.g.vscode then
    return
end

local M = {}
local DEFAULT_MAX_WIDTH = 80

-- Reversibly soft wrap selections at a fixed column while respecting comment prefixes,
-- inline comments, and existing indentation. The helper toggles between wrapped and
-- unwrapped representations depending on the current layout.
--[[
[!] TODO BUG
When wrapping markdown headers or other prefixed lines, the current detection conflates
header markers with comment prefixes. We need stronger heuristics so leading "##" or
similar tokens are preserved rather than stripped.

[ ] TODO FEATURE
Handle partially wrapped selections by reflowing only the overflowing lines while leaving
shorter ones intact.

[ ] TODO IDEA
Allow storing the original layout in a scratch pad so users can revert to the previous
formatting even after edits.
--]]

local function normalize_range(start_line, end_line)
    if type(start_line) ~= "number" or type(end_line) ~= "number" then
        return nil, nil
    end
    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end
    return start_line, end_line
end

local function get_mark_range()
    local start_line = vim.fn.getpos("'<")[2] - 1
    local end_line = vim.fn.getpos("'>")[2] - 1
    if start_line < 0 or end_line < 0 then
        return nil, nil
    end
    return normalize_range(start_line, end_line)
end

local function get_live_visual_range()
    local cursor_line = vim.fn.line(".")
    local visual_line = vim.fn.line("v")
    if cursor_line <= 0 or visual_line <= 0 then
        return nil, nil
    end
    return normalize_range(cursor_line - 1, visual_line - 1)
end

local function exit_visual_mode()
    local mode = vim.api.nvim_get_mode().mode
    if mode == "v" or mode == "V" or mode == "\22" then
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    end
end

local function restore_cursor(cursor_line, cursor_col)
    if type(cursor_line) ~= "number" then
        return
    end

    local line_count = vim.api.nvim_buf_line_count(0)
    local target_line = math.min(math.max(cursor_line, 1), line_count)
    local line = vim.api.nvim_buf_get_lines(0, target_line - 1, target_line, false)[1] or ""
    local max_col = math.max(#line - 1, 0)
    local target_col = math.min(math.max(cursor_col or 0, 0), max_col)

    vim.api.nvim_win_set_cursor(0, { target_line, target_col })
end

local function strip_prefix(line, comment_prefix)
    if comment_prefix ~= "" and line:match("^%s*" .. vim.pesc(comment_prefix)) then
        return line:gsub("^%s*" .. vim.pesc(comment_prefix), "", 1)
    end
    return line:gsub("^%s*", "", 1)
end

local function unwrap_lines(lines, initial_indent, comment_prefix)
    local pieces = {}

    for _, line in ipairs(lines) do
        local piece = strip_prefix(line, comment_prefix)
        if piece ~= "" then
            pieces[#pieces + 1] = piece
        end
    end

    return {
        initial_indent .. comment_prefix .. table.concat(pieces, " "):gsub("%s+", " "),
    }
end

local function build_words(content)
    local words = {}
    local code_part, comment_part = content:match("^(.-)%s*(//.*)$")

    if code_part and comment_part then
        for word in code_part:gmatch("%S+") do
            words[#words + 1] = word
        end
        words[#words + 1] = comment_part
        return words
    end

    for word in content:gmatch("%S+") do
        words[#words + 1] = word
    end

    return words
end

local function wrap_lines(lines, initial_indent, comment_prefix, max_width)
    local content = strip_prefix(table.concat(lines, " "), comment_prefix)
    local words = build_words(content)
    local new_lines = {}
    local prefix = initial_indent .. comment_prefix
    local current_line = prefix
    local line_width = #current_line

    for _, word in ipairs(words) do
        local is_inline_comment = comment_prefix == "" and word:match("^//") ~= nil

        if is_inline_comment then
            if line_width > #initial_indent then
                new_lines[#new_lines + 1] = current_line
                current_line = initial_indent
            end
            current_line = current_line .. word
            line_width = #current_line
        else
            local separator = line_width > #prefix and " " or ""
            local candidate = current_line .. separator .. word
            if line_width > #prefix and #candidate > max_width then
                new_lines[#new_lines + 1] = current_line
                current_line = prefix .. word
            else
                current_line = candidate
            end
            line_width = #current_line
        end
    end

    if current_line ~= "" then
        new_lines[#new_lines + 1] = current_line
    end

    return new_lines
end

local function transform_lines(lines, max_width)
    if #lines == 0 then
        return {}
    end

    local initial_indent = lines[1]:match("^(%s*)") or ""
    local comment_prefix = lines[1]:match("^%s*([%-/]+%s*)") or ""

    if #lines > 1 then
        return unwrap_lines(lines, initial_indent, comment_prefix)
    end

    return wrap_lines(lines, initial_indent, comment_prefix, max_width)
end

local function run(opts)
    opts = opts or {}
    local start_line, end_line = normalize_range(opts.start_line, opts.end_line)
    local max_width = opts.max_width or DEFAULT_MAX_WIDTH

    if start_line == nil or end_line == nil then
        start_line, end_line = get_mark_range()
    end
    if start_line == nil or end_line == nil then
        return
    end

    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
    if #lines == 0 then
        return
    end

    local new_lines = transform_lines(lines, max_width)
    vim.api.nvim_buf_set_lines(0, start_line, end_line + 1, false, new_lines)
    restore_cursor(opts.cursor_line, opts.cursor_col)
end

function M.run(opts)
    return run(opts)
end

function M.run_visual_selection(opts)
    local start_line, end_line = get_live_visual_range()
    if start_line == nil or end_line == nil then
        return run(opts)
    end

    local scheduled_opts = vim.tbl_extend("force", opts or {}, {
        start_line = start_line,
        end_line = end_line,
        cursor_line = start_line + 1,
        cursor_col = 0,
    })

    exit_visual_mode()

    vim.schedule(function()
        run(scheduled_opts)
    end)
end

return M
