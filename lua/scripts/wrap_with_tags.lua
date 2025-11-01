if vim.g.vscode then
    return
end

local M = {}

-- Wrap normal and visual selections with user-specified tags, preserving indentation
-- and supporting block selections.
local function run()
    local mode = vim.api.nvim_get_mode().mode
    if mode == "v" or mode == "V" or mode == "\22" then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
        vim.cmd("sleep 10m")
    end

    local start_tag = vim.fn.input("Start tag (e.g. <div>, [START]): ")
    if start_tag == "" then
        return
    end

    local end_tag = vim.fn.input("End tag (e.g. </div>, [END]): ")
    if end_tag == "" then
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local has_visual_selection = start_pos[2] ~= 0 and end_pos[2] ~= 0

    if not has_visual_selection then
        local line_num = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_get_lines(buf, line_num - 1, line_num, false)
        if #lines == 0 then
            return
        end

        local indent = lines[1]:match("^(%s*)")
        local new_lines = {
            indent .. start_tag,
            lines[1],
            indent .. end_tag,
        }
        vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, new_lines)
        return
    end

    if mode == "\22" or (start_pos[3] > 1 or end_pos[3] < 2147483647) then
        local start_line = start_pos[2] - 1
        local end_line = end_pos[2] - 1
        local start_col = start_pos[3] - 1
        local end_col = end_pos[3] - 1

        if start_col > end_col then
            start_col, end_col = end_col, start_col
        end

        local lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line + 1, false)
        if #lines == 0 then
            return
        end

        local block_lines = {}
        local min_indent = math.huge

        for _, line in ipairs(lines) do
            local content = line:sub(start_col + 1, end_col + 1)
            table.insert(block_lines, content)

            local indent_chars = line:sub(1, start_col):match("^(%s*)")
            if indent_chars then
                min_indent = math.min(min_indent, #indent_chars)
            end
        end

        local indent = (" "):rep(min_indent)
        local new_lines = { indent .. start_tag }
        for _, content in ipairs(block_lines) do
            table.insert(new_lines, indent .. content:match("^%s*(.*)"))
        end
        table.insert(new_lines, indent .. end_tag)

        vim.api.nvim_buf_set_lines(buf, start_line, start_line, false, new_lines)
        vim.api.nvim_buf_set_lines(buf, start_line + #new_lines, end_line + #new_lines + 1, false, {})
        return
    end

    local start_line = math.min(start_pos[2], end_pos[2]) - 1
    local end_line = math.max(start_pos[2], end_pos[2])

    local lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line, false)
    if #lines == 0 then
        return
    end

    local indent = ""
    for _, line in ipairs(lines) do
        if line:match("%S") then
            indent = line:match("^(%s*)") or ""
            break
        end
    end

    local new_lines = { indent .. start_tag }
    for _, line in ipairs(lines) do
        table.insert(new_lines, line)
    end
    table.insert(new_lines, indent .. end_tag)

    vim.api.nvim_buf_set_lines(buf, start_line, end_line, false, new_lines)
end

function M.run()
    return run()
end

return M
