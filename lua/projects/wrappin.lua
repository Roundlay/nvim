local M = {}

function M.Wrappin()
    -- Get the range of the visual selection
    local start_line = vim.fn.getpos("'<")[2] - 1
    local end_line = vim.fn.getpos("'>")[2] - 1

    -- Get the commentstring option of the current buffer
    local commentstring = vim.api.nvim_buf_get_option(0, 'commentstring')
    -- Extract the comment character from the commentstring
    local comment_char = ""
    if commentstring:find("%%s") then
        comment_char = commentstring:match("^(.*)%%s"):match("^%s*(.-)%s*$")
    end

    -- Get the lines in the visual selection
    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line+1, false)

    -- Join the lines into a single line
    local line_content = table.concat(lines, " ")

    -- If the line length is less than or equal to 80, do nothing and return
    if #line_content <= 80 then
        return
    end

    -- Get the leading whitespace of the line for indentation
    local indent = line_content:match("^%s*")
    -- Remove leading and trailing whitespace from the line
    local stripped = line_content:match("^%s*(.-)%s*$")

    -- Check if the line is already commented
    local is_commented = stripped:sub(1, #comment_char) == comment_char
    -- Remove leading comment characters from the stripped string
    stripped = stripped:gsub("^" .. comment_char .. "%s*", "")

    -- Split the stripped line into words
    local words = {}
    for word in stripped:gmatch("%S+") do
        table.insert(words, word)
    end

    -- Create a table to hold the new lines
    local new_lines = {}
    -- Initialize line with the comment character and indentation
    local line = indent .. (is_commented and comment_char .. " " or "")

    -- Add each word to the new line, ensuring that the length of the new
    -- line does not exceed 80 characters
    for _, word in ipairs(words) do
        if #line + #word > 80 then
            table.insert(new_lines, line)
            line = indent .. (is_commented and comment_char .. " " or "") .. word
        else
            line = line .. " " .. word
        end
    end
    table.insert(new_lines, line)

    -- Replace the original lines with the new lines
    vim.api.nvim_buf_set_lines(0, start_line, end_line+1, false, new_lines)
end

return M
