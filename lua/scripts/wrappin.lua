if vim.g.vscode then
    return
end

local M = {}

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

local function run()
    local start_line = vim.fn.getpos("'<")[2] - 1
    local end_line = vim.fn.getpos("'>")[2] - 1
    local max_width = 80

    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
    if #lines == 0 then
        return
    end

    local initial_indent = lines[1]:match("^(%s*)") or ""
    local comment_prefix = lines[1]:match("^%s*([%-/]+%s*)") or ""
    local first_is_comment = comment_prefix ~= "" and lines[1]:match("^%s*" .. vim.pesc(comment_prefix)) ~= nil

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
        local content = {}
        for _, line in ipairs(lines) do
            local cleaned = line:gsub("^%s*" .. vim.pesc(comment_prefix), "", 1)
            table.insert(content, cleaned)
        end
        local single_line = initial_indent .. comment_prefix .. table.concat(content, " "):gsub("%s+", " ")
        vim.api.nvim_buf_set_lines(0, start_line, end_line + 1, false, { single_line })
        return
    end

    local content = lines[1]
    local words = {}

    if content:match("^%s*[%-/]+%s+") then
        content = content:gsub("^%s*" .. vim.pesc(comment_prefix), "")
        for word in content:gmatch("%S+") do
            table.insert(words, word)
        end
    else
        content = content:gsub("^%s*" .. vim.pesc(comment_prefix), "")
        local code_part, comment_part = content:match("^(.-)%s*(//.*)$")
        if code_part and comment_part then
            for word in code_part:gmatch("%S+") do
                table.insert(words, word)
            end
            table.insert(words, comment_part)
        else
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
        local is_comment = not content:match("^%s*[%-/]+%s+") and word:match("^//")

        if is_comment then
            if line_width > #initial_indent then
                table.insert(new_lines, current_line)
                current_line = initial_indent
                line_width = #current_line
            end
            current_line = current_line .. word
            line_width = #current_line
        else
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

    vim.api.nvim_buf_set_lines(0, start_line, end_line + 1, false, new_lines)
end

function M.run()
    return run()
end

return M
