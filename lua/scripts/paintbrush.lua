-- paintbrush.lua
-- A Neovim plugin for drawing ASCII art/diagrams using virtual text overlays.
-- Mouse-first design with click-and-drag painting.

if vim.g.vscode then
    return
end

local M = {}

local ns = vim.api.nvim_create_namespace('Paintbrush')
local cursor_ns = vim.api.nvim_create_namespace('PaintbrushCursor')

local state = {
    enabled = false,
    buf = nil,
    canvas = {},              -- Sparse 2D: canvas[row][col] = {char, hl}
    extmark_ids = {},         -- Track extmark ID per row for updates
    cursor = {row = 0, col = 0},
    brush_char = '*',
    brush_hl = 'PaintbrushStroke',
    dragging = false,
    augroup = nil,            -- Autocmd group for buffer change detection
}

--------------------------------------------------------------------------------
-- Highlights
--------------------------------------------------------------------------------

local function setup_highlights()
    vim.api.nvim_set_hl(0, 'PaintbrushStroke', {link = 'String'})
    vim.api.nvim_set_hl(0, 'PaintbrushCursor', {link = 'Cursor'})
end

--------------------------------------------------------------------------------
-- Buffer Helpers
--------------------------------------------------------------------------------

-- Ensure buffer has at least `needed` lines by padding with empty lines
local function ensure_lines(needed)
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        return false
    end
    local line_count = vim.api.nvim_buf_line_count(state.buf)
    if needed >= line_count then
        local padding = {}
        for _ = 1, (needed - line_count + 1) do
            padding[#padding + 1] = ''
        end
        vim.api.nvim_buf_set_lines(state.buf, line_count, line_count, false, padding)
    end
    return true
end

-- Get the text area offset (line numbers, sign column, fold column, etc.)
local function get_textoff()
    local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())
    if wininfo and wininfo[1] then
        return wininfo[1].textoff or 0
    end
    return 0
end

--------------------------------------------------------------------------------
-- Canvas Rendering
--------------------------------------------------------------------------------

local function render_row(row)
    local row_data = state.canvas[row]

    -- If row has no data, delete any existing extmark
    if not row_data or not next(row_data) then
        if state.extmark_ids[row] then
            pcall(vim.api.nvim_buf_del_extmark, state.buf, ns, state.extmark_ids[row])
            state.extmark_ids[row] = nil
        end
        return
    end

    -- Collect and sort columns
    local cols = {}
    for c in pairs(row_data) do
        cols[#cols + 1] = c
    end
    table.sort(cols)

    -- Build virt_text chunks with transparent padding
    local chunks = {}
    local prev_end = 0
    for _, col in ipairs(cols) do
        local paint = row_data[col]
        if col > prev_end then
            chunks[#chunks + 1] = {string.rep(' ', col - prev_end), nil}
        end
        chunks[#chunks + 1] = {paint.char, paint.hl}
        prev_end = col + vim.fn.strdisplaywidth(paint.char)
    end

    -- Use existing extmark ID if available (updates in place)
    local opts = {
        virt_text = chunks,
        virt_text_pos = 'overlay',
        priority = 200,
    }
    if state.extmark_ids[row] then
        opts.id = state.extmark_ids[row]
    end

    local id = vim.api.nvim_buf_set_extmark(state.buf, ns, row, 0, opts)
    state.extmark_ids[row] = id
end

local function render_all()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        return
    end
    vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
    state.extmark_ids = {}  -- Reset tracking after clear
    for row in pairs(state.canvas) do
        render_row(row)
    end
end

--------------------------------------------------------------------------------
-- Cursor Rendering (Keyboard Mode)
--------------------------------------------------------------------------------

local function render_cursor()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        return
    end
    vim.api.nvim_buf_clear_namespace(state.buf, cursor_ns, 0, -1)
    if not state.enabled then
        return
    end

    local row, col = state.cursor.row, state.cursor.col

    -- Ensure buffer has enough lines for cursor
    ensure_lines(row)

    vim.api.nvim_buf_set_extmark(state.buf, cursor_ns, row, 0, {
        virt_text = {
            {string.rep(' ', col), nil},
            {'\u{2588}', 'PaintbrushCursor'}  -- Full block character
        },
        virt_text_pos = 'overlay',
        priority = 250,
    })
end

--------------------------------------------------------------------------------
-- Paint/Erase Operations
--------------------------------------------------------------------------------

local function paint_at(row, col)
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        return
    end
    if row < 0 or col < 0 then
        return
    end

    -- Ensure buffer has enough lines
    if not ensure_lines(row) then
        return
    end

    state.canvas[row] = state.canvas[row] or {}
    state.canvas[row][col] = {char = state.brush_char, hl = state.brush_hl}
    render_row(row)
end

local function erase_at(row, col)
    if state.canvas[row] then
        state.canvas[row][col] = nil
        if not next(state.canvas[row]) then
            state.canvas[row] = nil
        end
        render_row(row)  -- Only re-render affected row
    end
end

--------------------------------------------------------------------------------
-- Mouse Event Handlers
--------------------------------------------------------------------------------

-- Convert mouse position to canvas coordinates (row, col)
-- Uses winrow (window row) to allow clicking below buffer content
-- Uses wincol (window column) adjusted for text offset
local function mouse_to_canvas()
    local pos = vim.fn.getmousepos()
    if pos.winrow <= 0 then
        return nil, nil
    end

    -- Convert window row to buffer line (accounting for scroll)
    local first_visible = vim.fn.line('w0')  -- 1-indexed
    local row = first_visible + pos.winrow - 2  -- Convert to 0-indexed

    local textoff = get_textoff()
    local col = pos.wincol - textoff - 1  -- Visual column, 0-indexed

    if row < 0 then
        row = 0
    end
    if col < 0 then
        col = 0
    end

    return row, col
end

-- Escape visual mode if active
local function escape_visual()
    local mode = vim.api.nvim_get_mode().mode
    if mode:match('[vVsS\x16\x13]') then  -- Visual, visual-line, select modes, ctrl-v, ctrl-s
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
    end
end

local function on_left_click()
    if not state.enabled then
        return
    end
    escape_visual()
    state.dragging = true
    local row, col = mouse_to_canvas()
    if row then
        paint_at(row, col)
    end
end

local function on_left_drag()
    if not state.enabled then
        return
    end
    escape_visual()
    if not state.dragging then
        state.dragging = true
    end
    local row, col = mouse_to_canvas()
    if row then
        paint_at(row, col)
    end
end

local function on_left_release()
    state.dragging = false
    escape_visual()
end

local function on_right_click()
    if not state.enabled then
        return
    end
    escape_visual()
    local row, col = mouse_to_canvas()
    if row then
        erase_at(row, col)
    end
end

local function on_right_drag()
    if not state.enabled then
        return
    end
    escape_visual()
    local row, col = mouse_to_canvas()
    if row then
        erase_at(row, col)
    end
end

--------------------------------------------------------------------------------
-- Keyboard Movement
--------------------------------------------------------------------------------

local function move(dr, dc)
    local new_row = state.cursor.row + dr
    local new_col = state.cursor.col + dc

    -- Allow free movement, buffer will be extended as needed
    new_row = math.max(0, new_row)
    new_col = math.max(0, new_col)

    state.cursor.row = new_row
    state.cursor.col = new_col
    render_cursor()
end

local function paint_at_cursor()
    paint_at(state.cursor.row, state.cursor.col)
end

local function erase_at_cursor()
    erase_at(state.cursor.row, state.cursor.col)
end

--------------------------------------------------------------------------------
-- Keymap Management
--------------------------------------------------------------------------------

local function install_keymaps()
    local buf = state.buf
    local opts = {buffer = buf, silent = true, nowait = true}

    -- Mouse: Use <Cmd> style to avoid mode changes, nowait to prevent delays
    local mouse_opts = {silent = true, nowait = true}
    for _, mode in ipairs({'n', 'v', 'x', 's'}) do
        vim.keymap.set(mode, '<LeftMouse>', '<Cmd>lua require("scripts.paintbrush").handle_left_click()<CR>', mouse_opts)
        vim.keymap.set(mode, '<LeftDrag>', '<Cmd>lua require("scripts.paintbrush").handle_left_drag()<CR>', mouse_opts)
        vim.keymap.set(mode, '<LeftRelease>', '<Cmd>lua require("scripts.paintbrush").handle_left_release()<CR>', mouse_opts)
        vim.keymap.set(mode, '<RightMouse>', '<Cmd>lua require("scripts.paintbrush").handle_right_click()<CR>', mouse_opts)
        vim.keymap.set(mode, '<RightDrag>', '<Cmd>lua require("scripts.paintbrush").handle_right_drag()<CR>', mouse_opts)
        -- Multi-click: treat as regular clicks to prevent word/line selection
        vim.keymap.set(mode, '<2-LeftMouse>', '<Cmd>lua require("scripts.paintbrush").handle_left_click()<CR>', mouse_opts)
        vim.keymap.set(mode, '<3-LeftMouse>', '<Cmd>lua require("scripts.paintbrush").handle_left_click()<CR>', mouse_opts)
        vim.keymap.set(mode, '<4-LeftMouse>', '<Cmd>lua require("scripts.paintbrush").handle_left_click()<CR>', mouse_opts)
        vim.keymap.set(mode, '<2-LeftDrag>', '<Cmd>lua require("scripts.paintbrush").handle_left_drag()<CR>', mouse_opts)
        vim.keymap.set(mode, '<3-LeftDrag>', '<Cmd>lua require("scripts.paintbrush").handle_left_drag()<CR>', mouse_opts)
        vim.keymap.set(mode, '<4-LeftDrag>', '<Cmd>lua require("scripts.paintbrush").handle_left_drag()<CR>', mouse_opts)
        vim.keymap.set(mode, '<2-LeftRelease>', '<Cmd>lua require("scripts.paintbrush").handle_left_release()<CR>', mouse_opts)
        vim.keymap.set(mode, '<3-LeftRelease>', '<Cmd>lua require("scripts.paintbrush").handle_left_release()<CR>', mouse_opts)
        vim.keymap.set(mode, '<4-LeftRelease>', '<Cmd>lua require("scripts.paintbrush").handle_left_release()<CR>', mouse_opts)
        vim.keymap.set(mode, '<2-RightMouse>', '<Cmd>lua require("scripts.paintbrush").handle_right_click()<CR>', mouse_opts)
        vim.keymap.set(mode, '<2-RightDrag>', '<Cmd>lua require("scripts.paintbrush").handle_right_drag()<CR>', mouse_opts)
    end

    -- Keyboard (buffer-local)
    vim.keymap.set('n', 'h', function() move(0, -1) end, opts)
    vim.keymap.set('n', 'j', function() move(1, 0) end, opts)
    vim.keymap.set('n', 'k', function() move(-1, 0) end, opts)
    vim.keymap.set('n', 'l', function() move(0, 1) end, opts)
    vim.keymap.set('n', 'p', paint_at_cursor, opts)
    vim.keymap.set('n', 'P', erase_at_cursor, opts)
    vim.keymap.set('n', '<Esc>', M.disable, opts)
end

local function remove_keymaps()
    local buf = state.buf
    -- Remove mouse keymaps for all modes
    local mouse_events = {
        '<LeftMouse>', '<LeftDrag>', '<LeftRelease>',
        '<RightMouse>', '<RightDrag>',
        '<2-LeftMouse>', '<3-LeftMouse>', '<4-LeftMouse>',
        '<2-LeftDrag>', '<3-LeftDrag>', '<4-LeftDrag>',
        '<2-LeftRelease>', '<3-LeftRelease>', '<4-LeftRelease>',
        '<2-RightMouse>', '<2-RightDrag>',
    }
    for _, mode in ipairs({'n', 'v', 'x', 's'}) do
        for _, event in ipairs(mouse_events) do
            pcall(vim.keymap.del, mode, event)
        end
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.keymap.del, 'n', 'h', {buffer = buf})
        pcall(vim.keymap.del, 'n', 'j', {buffer = buf})
        pcall(vim.keymap.del, 'n', 'k', {buffer = buf})
        pcall(vim.keymap.del, 'n', 'l', {buffer = buf})
        pcall(vim.keymap.del, 'n', 'p', {buffer = buf})
        pcall(vim.keymap.del, 'n', 'P', {buffer = buf})
        pcall(vim.keymap.del, 'n', '<Esc>', {buffer = buf})
    end
end

--------------------------------------------------------------------------------
-- Enable/Disable Mode
--------------------------------------------------------------------------------

function M.enable()
    if state.enabled then
        return
    end

    state.enabled = true
    local current_buf = vim.api.nvim_get_current_buf()

    -- Only reset canvas if switching to a different buffer
    if state.buf ~= current_buf then
        state.buf = current_buf
        state.canvas = {}
        state.extmark_ids = {}
        state.augroup = nil  -- Reset augroup for new buffer
    end
    -- Otherwise preserve existing canvas data

    state.dragging = false

    local cursor = vim.api.nvim_win_get_cursor(0)
    state.cursor = {row = cursor[1] - 1, col = cursor[2]}

    vim.o.mouse = 'a'
    vim.o.mousemoveevent = true

    setup_highlights()
    install_keymaps()
    render_cursor()

    -- Set up autocmd to re-render canvas when buffer changes (keeps extmarks static)
    -- This persists even after disable, as long as canvas has data
    if not state.augroup then
        state.augroup = vim.api.nvim_create_augroup('PaintbrushBuffer', {clear = true})
        vim.api.nvim_create_autocmd({'TextChanged', 'TextChangedI'}, {
            group = state.augroup,
            buffer = state.buf,
            callback = function()
                -- Re-render all canvas extmarks to maintain positions
                vim.schedule(function()
                    if not vim.tbl_isempty(state.canvas) then
                        render_all()
                    end
                end)
            end,
        })
    end

    vim.notify('Paintbrush enabled. Left-click/drag: paint, Right-click: erase, Esc: exit')
end

function M.disable()
    if not state.enabled then
        return
    end

    state.enabled = false
    remove_keymaps()

    -- Note: augroup is NOT deleted here - it keeps canvas static even after disable
    -- It gets cleaned up when M.clear() is called

    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        vim.api.nvim_buf_clear_namespace(state.buf, cursor_ns, 0, -1)
    end
    -- Canvas extmarks remain visible and protected by autocmd

    vim.notify('Paintbrush disabled')
end

function M.toggle()
    if state.enabled then
        M.disable()
    else
        M.enable()
    end
end

--------------------------------------------------------------------------------
-- Exported Mouse Handlers (for <Cmd> mappings)
--------------------------------------------------------------------------------

function M.handle_left_click()
    on_left_click()
end

function M.handle_left_drag()
    on_left_drag()
end

function M.handle_left_release()
    on_left_release()
end

function M.handle_right_click()
    on_right_click()
end

function M.handle_right_drag()
    on_right_drag()
end

--------------------------------------------------------------------------------
-- Command Interface
--------------------------------------------------------------------------------

function M.clear()
    state.canvas = {}
    state.extmark_ids = {}
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
    end
    -- Clean up autocmd since there's no canvas to protect
    if state.augroup then
        pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
        state.augroup = nil
    end
    vim.notify('Canvas cleared')
end

function M.set_brush(char)
    if char and #char > 0 then
        state.brush_char = char:sub(1, 1)
        vim.notify('Brush set to: ' .. state.brush_char)
    end
end

function M.export()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        vim.notify('No valid buffer')
        return
    end
    if vim.tbl_isempty(state.canvas) then
        vim.notify('Nothing to export')
        return
    end

    -- Get all rows sorted
    local rows = {}
    for r in pairs(state.canvas) do
        rows[#rows + 1] = r
    end
    table.sort(rows)

    for _, row in ipairs(rows) do
        local line = vim.api.nvim_buf_get_lines(state.buf, row, row + 1, false)[1] or ''
        local cols = {}
        for c in pairs(state.canvas[row]) do
            cols[#cols + 1] = c
        end
        table.sort(cols)

        -- Expand line if needed and overlay painted chars
        local result = {}
        local line_len = #line
        local last_col = cols[#cols] or 0

        for i = 0, math.max(line_len - 1, last_col) do
            local painted = state.canvas[row][i]
            if painted then
                result[#result + 1] = painted.char
            elseif i < line_len then
                result[#result + 1] = line:sub(i + 1, i + 1)
            else
                result[#result + 1] = ' '
            end
        end

        vim.api.nvim_buf_set_lines(state.buf, row, row + 1, false, {table.concat(result)})
    end

    -- Clear canvas after export
    M.clear()
    vim.notify('Exported to buffer')
end

--------------------------------------------------------------------------------
-- User Commands
--------------------------------------------------------------------------------

vim.api.nvim_create_user_command('Paintbrush', M.toggle, {})
vim.api.nvim_create_user_command('PaintbrushClear', M.clear, {})
vim.api.nvim_create_user_command('PaintbrushBrush', function(opts)
    M.set_brush(opts.args)
end, {nargs = 1})
vim.api.nvim_create_user_command('PaintbrushExport', M.export, {})

--------------------------------------------------------------------------------
-- Module Export
--------------------------------------------------------------------------------

function M.run()
    M.toggle()
end

return M
