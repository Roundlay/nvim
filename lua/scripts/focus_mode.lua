if vim.g.vscode then
    return
end

local M = {}

local api = vim.api
local floor = math.floor
local max = math.max
local min = math.min

local decoration_ns = api.nvim_create_namespace("focus-mode-decoration")

local dim_namespace = -1
local commands_registered = false
local autocmd_group = nil
local provider_registered = false

local state_by_window = {}

local excluded_filetypes = {
    TelescopePrompt = true,
    help = true,
    lazy = true,
    oil = true,
}

local excluded_buftypes = {
    nofile = true,
    prompt = true,
    quickfix = true,
    terminal = true,
}

local passthrough_highlight_keys = {
    "bg",
    "blend",
    "bold",
    "cterm",
    "ctermbg",
    "ctermfg",
    "default",
    "italic",
    "nocombine",
    "reverse",
    "standout",
    "strikethrough",
    "undercurl",
    "underdashed",
    "underdotted",
    "underdouble",
    "underline",
}

local sentence_punctuation = {
    ["."] = true,
    ["!"] = true,
    ["?"] = true,
}

local sentence_trailing = {
    ["'"] = true,
    ['"'] = true,
    [")"] = true,
    ["]"] = true,
    ["}"] = true,
}

local sentence_leading = {
    ["'"] = true,
    ['"'] = true,
    [")"] = true,
    ["]"] = true,
    ["}"] = true,
    ["\n"] = true,
    ["\r"] = true,
    ["\t"] = true,
    [" "] = true,
}

local function resolve_winid(winid)
    if winid == nil or winid == 0 then
        return api.nvim_get_current_win()
    end
    return winid
end

local function clamp_channel(value)
    if value < 0 then
        return 0
    end
    if value > 255 then
        return 255
    end
    return floor(value + 0.5)
end

local function blend_rgb(fg, bg, alpha)
    local fg_r = floor(fg / 0x10000) % 0x100
    local fg_g = floor(fg / 0x100) % 0x100
    local fg_b = fg % 0x100

    local bg_r = floor(bg / 0x10000) % 0x100
    local bg_g = floor(bg / 0x100) % 0x100
    local bg_b = bg % 0x100

    local r = clamp_channel((fg_r * alpha) + (bg_r * (1 - alpha)))
    local g = clamp_channel((fg_g * alpha) + (bg_g * (1 - alpha)))
    local b = clamp_channel((fg_b * alpha) + (bg_b * (1 - alpha)))

    return (r * 0x10000) + (g * 0x100) + b
end

local function get_hl(name)
    local ok, hl = pcall(api.nvim_get_hl, 0, { name = name, link = false })
    if not ok or type(hl) ~= "table" then
        return nil
    end
    return hl
end

local function get_dim_alpha()
    local alpha = vim.g.focus_mode_dim_alpha
    if type(alpha) ~= "number" or alpha <= 0 or alpha >= 1 then
        return 0.32
    end
    return alpha
end

local function get_default_mode()
    if vim.g.focus_mode_default_mode == "paragraph" then
        return "paragraph"
    end
    return "sentence"
end

local function normalize_mode(mode)
    if mode == "paragraph" then
        return "paragraph"
    end
    return "sentence"
end

local function set_active_highlight()
    local normal = get_hl("Normal") or {}
    local active = {}

    if normal.fg then
        active.fg = normal.fg
    end
    if normal.bg then
        active.bg = normal.bg
    end

    api.nvim_set_hl(0, "FocusModeActive", active)
end

local function rebuild_dim_namespace()
    local normal = get_hl("Normal") or {}
    local background = normal.bg or 0x000000
    local alpha = get_dim_alpha()
    local namespace = api.nvim_create_namespace("")

    for _, group_name in ipairs(vim.fn.getcompletion("", "highlight")) do
        local hl = get_hl(group_name)
        if hl and next(hl) ~= nil then
            local dimmed = {}

            if hl.fg then
                dimmed.fg = blend_rgb(hl.fg, background, alpha)
            end
            if hl.sp then
                dimmed.sp = blend_rgb(hl.sp, background, alpha)
            end

            for _, key in ipairs(passthrough_highlight_keys) do
                if hl[key] ~= nil then
                    dimmed[key] = hl[key]
                end
            end

            api.nvim_set_hl(namespace, group_name, dimmed)
        end
    end

    dim_namespace = namespace
    set_active_highlight()

    for winid, state in pairs(state_by_window) do
        if state.enabled and api.nvim_win_is_valid(winid) and not state.suspended then
            api.nvim_win_set_hl_ns(winid, dim_namespace)
        end
    end
end

local function is_blank(line)
    return line == nil or line:match("^%s*$") ~= nil
end

local function window_allowed(winid)
    if not api.nvim_win_is_valid(winid) then
        return false
    end

    local config = api.nvim_win_get_config(winid)
    if config.relative ~= "" then
        return false
    end

    return true
end

local function buffer_allowed(bufnr)
    if not api.nvim_buf_is_valid(bufnr) then
        return false
    end

    if vim.b[bufnr].focus_disable then
        return false
    end

    local filetype = api.nvim_get_option_value("filetype", { buf = bufnr })
    local buftype = api.nvim_get_option_value("buftype", { buf = bufnr })

    if excluded_filetypes[filetype] or excluded_buftypes[buftype] then
        return false
    end

    return true
end

local function get_current_buffer_state(winid)
    local bufnr = api.nvim_win_get_buf(winid)
    local cursor = api.nvim_win_get_cursor(winid)
    local row = cursor[1] - 1
    local col = cursor[2]
    local changedtick = api.nvim_buf_get_changedtick(bufnr)
    return bufnr, row, col, changedtick
end

local function get_paragraph_bounds(bufnr, row)
    local current_line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
    if is_blank(current_line) then
        return row, row
    end

    local line_count = api.nvim_buf_line_count(bufnr)
    local start_row = row
    local end_row = row

    while start_row > 0 do
        local line = api.nvim_buf_get_lines(bufnr, start_row - 1, start_row, false)[1]
        if is_blank(line) then
            break
        end
        start_row = start_row - 1
    end

    while end_row + 1 < line_count do
        local line = api.nvim_buf_get_lines(bufnr, end_row + 1, end_row + 2, false)[1]
        if is_blank(line) then
            break
        end
        end_row = end_row + 1
    end

    return start_row, end_row
end

local function build_offsets(lines)
    local offsets = {}
    local total = 0

    for i, line in ipairs(lines) do
        offsets[i] = total
        total = total + #line
        if i < #lines then
            total = total + 1
        end
    end

    return offsets, total
end

local function find_sentence_bounds(text, cursor_offset)
    local text_len = #text
    if text_len == 0 then
        return 0, 0
    end

    local start_scan = min(max(cursor_offset, 0), max(text_len - 1, 0)) + 1
    local start_pos = 1

    for idx = start_scan, 1, -1 do
        local ch = text:sub(idx, idx)
        if sentence_punctuation[ch] then
            start_pos = idx + 1
            break
        end
    end

    while start_pos <= text_len do
        local ch = text:sub(start_pos, start_pos)
        if not sentence_leading[ch] then
            break
        end
        start_pos = start_pos + 1
    end

    local end_pos = text_len + 1
    local end_scan = min(max(cursor_offset + 1, 1), text_len)

    for idx = end_scan, text_len do
        local ch = text:sub(idx, idx)
        if sentence_punctuation[ch] then
            end_pos = idx + 1
            while end_pos <= text_len do
                local trailing = text:sub(end_pos, end_pos)
                if not sentence_trailing[trailing] then
                    break
                end
                end_pos = end_pos + 1
            end
            break
        end
    end

    local start_col = max(start_pos - 1, 0)
    local end_col = max(end_pos - 1, 0)

    if end_col <= start_col then
        end_col = min(text_len, start_col + 1)
    end

    return start_col, end_col
end

local function build_line_segments(lines, start_row, start_col, end_col)
    local offsets = build_offsets(lines)
    local segments = {}
    local min_row = nil
    local max_row = nil

    for i, line in ipairs(lines) do
        local row = start_row + i - 1
        local line_start = offsets[i]
        local line_end = line_start + #line
        local overlap_start = max(start_col, line_start)
        local overlap_end = min(end_col, line_end)

        if overlap_start < overlap_end then
            segments[row] = {
                start_col = overlap_start - line_start,
                end_col = overlap_end - line_start,
                full_line = overlap_start == line_start and overlap_end == line_end,
            }

            if min_row == nil or row < min_row then
                min_row = row
            end
            if max_row == nil or row > max_row then
                max_row = row
            end
        end
    end

    return segments, min_row, max_row
end

local function compute_focus_segments(bufnr, row, col, mode)
    local paragraph_start, paragraph_end = get_paragraph_bounds(bufnr, row)
    local lines = api.nvim_buf_get_lines(bufnr, paragraph_start, paragraph_end + 1, false)

    if mode == "paragraph" then
        local segments = {}
        for i, line in ipairs(lines) do
            local line_row = paragraph_start + i - 1
            if #line > 0 then
                segments[line_row] = {
                    start_col = 0,
                    end_col = #line,
                    full_line = true,
                }
            end
        end
        return segments, paragraph_start, paragraph_end
    end

    local offsets = build_offsets(lines)
    local paragraph_text = table.concat(lines, "\n")
    local paragraph_row = row - paragraph_start + 1
    local current_line = lines[paragraph_row] or ""
    local cursor_col = min(col, #current_line)
    local cursor_offset = (offsets[paragraph_row] or 0) + cursor_col
    local sentence_start, sentence_end = find_sentence_bounds(paragraph_text, cursor_offset)
    local segments, min_row, max_row = build_line_segments(lines, paragraph_start, sentence_start, sentence_end)

    if next(segments) ~= nil then
        return segments, min_row, max_row
    end

    if #current_line > 0 then
        return {
            [row] = {
                start_col = 0,
                end_col = #current_line,
                full_line = true,
            },
        }, row, row
    end

    return {}, row, row
end

local function suspend_window(winid)
    local state = state_by_window[winid]
    if not state then
        return
    end

    state.suspended = true
    state.segments = {}
    state.min_row = nil
    state.max_row = nil

    if api.nvim_win_is_valid(winid) then
        api.nvim_win_set_hl_ns(winid, -1)
    end
end

local function refresh_window(winid)
    local state = state_by_window[winid]
    if not state or not state.enabled then
        return
    end

    if not window_allowed(winid) then
        suspend_window(winid)
        return
    end

    local bufnr, row, col, changedtick = get_current_buffer_state(winid)
    if not buffer_allowed(bufnr) then
        suspend_window(winid)
        state.bufnr = bufnr
        return
    end

    if dim_namespace < 0 then
        rebuild_dim_namespace()
    end

    if state.bufnr == bufnr
        and state.row == row
        and state.col == col
        and state.changedtick == changedtick
        and not state.suspended
    then
        return
    end

    local segments, min_row, max_row = compute_focus_segments(bufnr, row, col, state.mode)

    state.bufnr = bufnr
    state.row = row
    state.col = col
    state.changedtick = changedtick
    state.segments = segments
    state.min_row = min_row
    state.max_row = max_row
    state.suspended = false

    api.nvim_win_set_hl_ns(winid, dim_namespace)
end

local function has_enabled_windows()
    for winid, state in pairs(state_by_window) do
        if state.enabled and api.nvim_win_is_valid(winid) then
            return true
        end
    end
    return false
end

local function register_provider()
    if provider_registered then
        return
    end

    api.nvim_set_decoration_provider(decoration_ns, {
        on_start = function()
            return has_enabled_windows()
        end,
        on_win = function(_, winid, bufnr)
            local state = state_by_window[winid]
            if not state or not state.enabled or state.suspended then
                return false
            end
            if state.bufnr ~= bufnr then
                return false
            end
            return true
        end,
        on_line = function(_, winid, bufnr, row)
            local state = state_by_window[winid]
            if not state or not state.enabled or state.suspended then
                return
            end

            local segment = state.segments[row]
            if segment and segment.full_line then
                api.nvim_set_hl_ns_fast(0)
                return
            end

            if dim_namespace >= 0 then
                api.nvim_set_hl_ns_fast(dim_namespace)
            end

            if not segment or segment.end_col <= segment.start_col then
                return
            end

            api.nvim_buf_set_extmark(bufnr, decoration_ns, row, segment.start_col, {
                end_row = row,
                end_col = segment.end_col,
                hl_group = "FocusModeActive",
                ephemeral = true,
                priority = 200,
            })
        end,
    })

    provider_registered = true
end

local function redraw()
    vim.cmd("redraw")
end

local function refresh_all_windows()
    for winid, state in pairs(state_by_window) do
        if state.enabled then
            refresh_window(winid)
        end
    end
end

local function cleanup_closed_window(winid)
    state_by_window[winid] = nil
end

local function register_autocmds()
    if autocmd_group then
        return
    end

    autocmd_group = api.nvim_create_augroup("FocusMode", { clear = true })

    api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "CursorMovedI", "InsertLeave", "TextChanged", "TextChangedI", "WinEnter" }, {
        group = autocmd_group,
        callback = function(ev)
            local winid = ev.win
            if type(winid) ~= "number" or winid == 0 then
                winid = api.nvim_get_current_win()
            end
            if state_by_window[winid] then
                refresh_window(winid)
            end
        end,
    })

    api.nvim_create_autocmd("ColorScheme", {
        group = autocmd_group,
        callback = function()
            rebuild_dim_namespace()
            refresh_all_windows()
            redraw()
        end,
    })

    api.nvim_create_autocmd("WinClosed", {
        group = autocmd_group,
        callback = function(ev)
            local winid = tonumber(ev.match)
            if winid then
                cleanup_closed_window(winid)
            end
        end,
    })
end

function M.enable(winid, mode)
    winid = resolve_winid(winid)
    if not window_allowed(winid) then
        return false
    end

    local bufnr = api.nvim_win_get_buf(winid)
    if not buffer_allowed(bufnr) then
        return false
    end

    local state = state_by_window[winid] or {}
    state.enabled = true
    state.mode = normalize_mode(mode or state.mode or get_default_mode())
    state_by_window[winid] = state

    refresh_window(winid)
    redraw()
    return true
end

function M.disable(winid)
    winid = resolve_winid(winid)
    local state = state_by_window[winid]
    if not state then
        return false
    end

    state.enabled = false
    state.suspended = true
    state.segments = {}

    if api.nvim_win_is_valid(winid) then
        api.nvim_win_set_hl_ns(winid, -1)
    end

    redraw()
    return true
end

function M.toggle(winid)
    winid = resolve_winid(winid)
    local state = state_by_window[winid]
    if state and state.enabled then
        return M.disable(winid)
    end
    return M.enable(winid)
end

function M.set_mode(mode, winid)
    return M.enable(winid, normalize_mode(mode))
end

local function complete_focus_mode()
    return { "off", "on", "paragraph", "sentence", "toggle" }
end

local function run_command(opts)
    local arg = opts.args ~= "" and opts.args or "toggle"

    if arg == "off" then
        M.disable(0)
        return
    end

    if arg == "on" then
        M.enable(0)
        return
    end

    if arg == "paragraph" or arg == "sentence" then
        M.set_mode(arg, 0)
        return
    end

    M.toggle(0)
end

local function register_commands()
    if commands_registered then
        return
    end

    api.nvim_create_user_command("FocusMode", run_command, {
        nargs = "?",
        complete = complete_focus_mode,
        desc = "Toggle or configure the iA-style writing focus mode.",
    })

    commands_registered = true
end

function M.setup()
    if vim.g._focus_mode_loaded then
        return
    end

    vim.g._focus_mode_loaded = true

    rebuild_dim_namespace()
    register_provider()
    register_autocmds()
    register_commands()
end

M.setup()

return M
