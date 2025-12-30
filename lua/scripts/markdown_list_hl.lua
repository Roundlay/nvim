-- markdown_list_hl.lua
-- Highlights markdown list markers with a single color.

local M = {}

local ns_id = vim.api.nvim_create_namespace("MarkdownListHighlight")

-- Configuration
M.config = {
    -- Highlight group for list markers
    hl_group = "MarkdownList1",
    -- Filetypes to apply highlighting
    filetypes = { markdown = true, ["markdown.pandoc"] = true },
}

-- Find the list marker position in a line
-- Returns (col_start, col_end) or nil if not a list line
local function get_marker_position(line)
    -- Match: leading whitespace, then marker (-, *, +), then space or tab
    local leading = line:match("^(%s*)[-*+][ \t]")
    if leading then
        return #leading, #leading + 1
    end
    -- Also match empty list items (marker at end of line)
    leading = line:match("^(%s*)[-*+]$")
    if leading then
        return #leading, #leading + 1
    end
    return nil, nil
end

-- Apply highlights to a buffer
local function apply_highlights(bufnr)
    -- Clear existing highlights
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    local ft = vim.bo[bufnr].filetype
    if not M.config.filetypes[ft] then
        return
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    for lnum, line in ipairs(lines) do
        local col_start, col_end = get_marker_position(line)
        if col_start then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, lnum - 1, col_start, {
                end_col = col_end,
                hl_group = M.config.hl_group,
                priority = 200, -- Higher than Treesitter (100)
            })
        end
    end
end

-- Debounce helper
local pending_buffers = {}
local function schedule_update(bufnr)
    if pending_buffers[bufnr] then
        return
    end
    pending_buffers[bufnr] = true
    vim.schedule(function()
        pending_buffers[bufnr] = nil
        if vim.api.nvim_buf_is_valid(bufnr) then
            apply_highlights(bufnr)
        end
    end)
end

function M.setup(opts)
    if opts then
        M.config = vim.tbl_deep_extend("force", M.config, opts)
    end

    local group = vim.api.nvim_create_augroup("MarkdownListHighlight", { clear = true })

    -- Apply on buffer enter and filetype change
    vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
        group = group,
        callback = function(args)
            schedule_update(args.buf)
        end,
    })

    -- Re-apply on text changes (debounced)
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = group,
        callback = function(args)
            local ft = vim.bo[args.buf].filetype
            if M.config.filetypes[ft] then
                schedule_update(args.buf)
            end
        end,
    })

    -- Apply to all existing markdown buffers
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
            local ft = vim.bo[bufnr].filetype
            if M.config.filetypes[ft] then
                schedule_update(bufnr)
            end
        end
    end
end

return M
