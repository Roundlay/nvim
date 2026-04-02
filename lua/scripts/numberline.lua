if vim.g.vscode then
    return
end

local M = {}

local api = vim.api
local v = vim.v
local abs = math.abs
local floor = math.floor
local ipairs = ipairs
local pcall = pcall
local tostring = tostring

local nvim_buf_is_valid = api.nvim_buf_is_valid
local nvim_buf_line_count = api.nvim_buf_line_count
local nvim_create_augroup = api.nvim_create_augroup
local nvim_create_autocmd = api.nvim_create_autocmd
local nvim_del_augroup_by_id = api.nvim_del_augroup_by_id
local nvim_get_hl = api.nvim_get_hl
local nvim_get_option_value = api.nvim_get_option_value
local nvim_get_current_win = api.nvim_get_current_win
local nvim_list_wins = api.nvim_list_wins
local nvim_set_hl = api.nvim_set_hl
local nvim_set_option_value = api.nvim_set_option_value
local nvim_win_del_var = api.nvim_win_del_var
local nvim_win_get_buf = api.nvim_win_get_buf
local nvim_win_get_var = api.nvim_win_get_var
local nvim_win_is_valid = api.nvim_win_is_valid
local nvim_win_set_var = api.nvim_win_set_var

local HL_NORMAL = "LineNr"
local HL_CURSOR = "CursorLineNr"
local HL_PREFIX = "LineNrPrefix"

local FMT_PREFIX = "%#LineNrPrefix#"
local FMT_NORMAL = "%#LineNr#"
local FMT_CURSOR = "%#CursorLineNr#"
local FMT_SUFFIX = "%#LineNr# %*"

local VAR_USER_CURSORLINEOPT = "_nl_user_cursorlineopt"
local VAR_CURSORLINE_FORCED = "_nl_cursorline_forced"

local EAGER_CACHE_LIMIT = 9999
local SEEDED_WIDTH_LIMIT = 5

local augroup = nil
local buf_digit_counts = {}
local zeros_lut = {}
local statuscolumn_cache = {}
-- Hot formatter data: [width][line_number] -> formatted string.
-- Split normal and cursor variants so the render path avoids per-number subtables.
local normal_line_cache = {}
local cursor_line_cache = {}

local excluded_filetypes = {
    TelescopePrompt = true,
    help = true,
    lazy = true,
}

local excluded_buftypes = {
    nofile = true,
    prompt = true,
    terminal = true,
}

local function get_hl(name)
    local ok, hl = pcall(nvim_get_hl, 0, { name = name, link = true })
    if not ok or type(hl) ~= "table" then
        return nil
    end
    return hl
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

local function scale_rgb(color, factor)
    local r = clamp_channel((floor(color / 0x10000) % 0x100) * factor)
    local g = clamp_channel((floor(color / 0x100) % 0x100) * factor)
    local b = clamp_channel((color % 0x100) * factor)
    return (r * 0x10000) + (g * 0x100) + b
end

local function apply_prefix_highlight()
    local line_nr_hl = get_hl(HL_NORMAL)
    if not line_nr_hl or not line_nr_hl.fg then
        return
    end

    local existing_prefix = get_hl(HL_PREFIX)
    if existing_prefix and existing_prefix.fg and existing_prefix.fg ~= line_nr_hl.fg then
        return
    end

    local normal_hl = get_hl("Normal")
    local dimmed_fg
    if normal_hl and normal_hl.bg then
        dimmed_fg = blend_rgb(line_nr_hl.fg, normal_hl.bg, 0.55)
    else
        dimmed_fg = scale_rgb(line_nr_hl.fg, 0.72)
    end

    local opts = { fg = dimmed_fg }
    if line_nr_hl.bg then
        opts.bg = line_nr_hl.bg
    end
    nvim_set_hl(0, HL_PREFIX, opts)
end

local function digit_count(n)
    if n < 10 then return 1 end
    if n < 100 then return 2 end
    if n < 1000 then return 3 end
    if n < 10000 then return 4 end
    if n < 100000 then return 5 end
    if n < 1000000 then return 6 end
    if n < 10000000 then return 7 end
    if n < 100000000 then return 8 end
    if n < 1000000000 then return 9 end
    return #tostring(n)
end

local function ensure_zero_row(width)
    local row = zeros_lut[width]
    if row then
        return row
    end

    row = {}
    for zero_count = 0, width do
        row[zero_count] = string.rep("0", zero_count)
    end
    zeros_lut[width] = row
    return row
end

local function ensure_statuscolumn_row(width)
    local row = statuscolumn_cache[width]
    if row then
        return row
    end

    row = {
        [0] = "%!v:lua.FormatLineNr(" .. width .. ",0)",
        [1] = "%!v:lua.FormatLineNr(" .. width .. ",1)",
    }
    statuscolumn_cache[width] = row
    return row
end

local function build_line_pair(width, num)
    local zero_row = ensure_zero_row(width)
    local digits = digit_count(num)
    local zero_count = width - digits
    if zero_count < 0 then
        zero_count = 0
    end

    local zeros = zero_row[zero_count]
    if zeros == nil then
        zeros = string.rep("0", zero_count)
        zero_row[zero_count] = zeros
    end

    local num_str = tostring(num)
    local prefix = FMT_PREFIX .. zeros
    return prefix .. FMT_NORMAL .. num_str .. FMT_SUFFIX,
        prefix .. FMT_CURSOR .. num_str .. FMT_SUFFIX
end

local function ensure_width_cache(width)
    local normal_cache = normal_line_cache[width]
    if normal_cache then
        return normal_cache, cursor_line_cache[width]
    end

    local zero_row = ensure_zero_row(width)
    local normal_prefixes = {}
    local cursor_prefixes = {}
    for zero_count = 0, width do
        local prefix = FMT_PREFIX .. zero_row[zero_count]
        normal_prefixes[zero_count] = prefix .. FMT_NORMAL
        cursor_prefixes[zero_count] = prefix .. FMT_CURSOR
    end

    ensure_statuscolumn_row(width)

    normal_cache = {}
    local cursor_cache = {}
    for num = 0, EAGER_CACHE_LIMIT do
        local zero_count = width - digit_count(num)
        if zero_count < 0 then
            zero_count = 0
        end
        local num_str = tostring(num)
        normal_cache[num] = normal_prefixes[zero_count] .. num_str .. FMT_SUFFIX
        cursor_cache[num] = cursor_prefixes[zero_count] .. num_str .. FMT_SUFFIX
    end

    normal_line_cache[width] = normal_cache
    cursor_line_cache[width] = cursor_cache
    return normal_cache, cursor_cache
end

local function get_window_var(winid, name)
    local ok, value = pcall(nvim_win_get_var, winid, name)
    if ok then
        return value
    end
    return nil
end

local function set_window_var(winid, name, value)
    pcall(nvim_win_set_var, winid, name, value)
end

local function clear_window_var(winid, name)
    pcall(nvim_win_del_var, winid, name)
end

local function clear_window(winid)
    if nvim_get_option_value("statuscolumn", { win = winid }) ~= "" then
        nvim_set_option_value("statuscolumn", "", { win = winid })
    end
end

local function is_excluded_buffer(buf)
    local ft = nvim_get_option_value("filetype", { buf = buf })
    if excluded_filetypes[ft] then
        return true
    end

    local bt = nvim_get_option_value("buftype", { buf = buf })
    return excluded_buftypes[bt] == true
end

local function ensure_cursorline(winid)
    if nvim_get_option_value("cursorline", { win = winid }) then
        return
    end

    if get_window_var(winid, VAR_USER_CURSORLINEOPT) == nil then
        set_window_var(winid, VAR_USER_CURSORLINEOPT, nvim_get_option_value("cursorlineopt", { win = winid }))
    end

    nvim_set_option_value("cursorlineopt", "number", { win = winid })
    nvim_set_option_value("cursorline", true, { win = winid })
    set_window_var(winid, VAR_CURSORLINE_FORCED, true)
end

local function update_window(winid)
    winid = winid or nvim_get_current_win()
    if not nvim_win_is_valid(winid) then
        return
    end

    local buf = nvim_win_get_buf(winid)
    if not nvim_buf_is_valid(buf) then
        clear_window(winid)
        return
    end

    if is_excluded_buffer(buf) then
        clear_window(winid)
        return
    end

    local number_on = nvim_get_option_value("number", { win = winid })
    local relative_on = nvim_get_option_value("relativenumber", { win = winid })
    if not number_on and not relative_on then
        clear_window(winid)
        return
    end

    ensure_cursorline(winid)

    local line_count = nvim_buf_line_count(buf)
    local digits = digit_count(line_count)
    local required_width = digits + 2

    if nvim_get_option_value("numberwidth", { win = winid }) ~= required_width then
        nvim_set_option_value("numberwidth", required_width, { win = winid })
    end

    local status_column = ensure_statuscolumn_row(digits)[relative_on and 1 or 0]
    if nvim_get_option_value("statuscolumn", { win = winid }) ~= status_column then
        nvim_set_option_value("statuscolumn", status_column, { win = winid })
    end

    buf_digit_counts[buf] = digits
end

local function update_buffer_windows(buf)
    for _, winid in ipairs(nvim_list_wins()) do
        if nvim_win_get_buf(winid) == buf then
            update_window(winid)
        end
    end
end

local function setup_autocmds()
    if augroup then
        return
    end

    augroup = nvim_create_augroup("Numberline", { clear = true })

    nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter", "WinNew", "WinResized" }, {
        group = augroup,
        callback = function(ev)
            update_window(ev.win or nvim_get_current_win())
        end,
    })

    nvim_create_autocmd("FileType", {
        group = augroup,
        callback = function(ev)
            update_buffer_windows(ev.buf)
        end,
    })

    nvim_create_autocmd("OptionSet", {
        group = augroup,
        pattern = { "relativenumber", "number" },
        callback = function()
            update_window()
        end,
    })

    nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
        group = augroup,
        callback = function(ev)
            local buf = ev.buf
            if not nvim_buf_is_valid(buf) then
                return
            end

            local digits = digit_count(nvim_buf_line_count(buf))
            if digits ~= (buf_digit_counts[buf] or 0) then
                buf_digit_counts[buf] = digits
                update_buffer_windows(buf)
            end
        end,
    })

    nvim_create_autocmd("BufWipeout", {
        group = augroup,
        callback = function(ev)
            buf_digit_counts[ev.buf] = nil
        end,
    })

    nvim_create_autocmd("OptionSet", {
        group = augroup,
        pattern = "cursorline",
        callback = function(ev)
            local winid = ev.win or nvim_get_current_win()
            if not nvim_win_is_valid(winid) then
                return
            end

            if nvim_get_option_value("cursorline", { win = winid }) then
                local restore = get_window_var(winid, VAR_USER_CURSORLINEOPT)
                if restore ~= nil then
                    nvim_set_option_value("cursorlineopt", restore, { win = winid })
                end
                clear_window_var(winid, VAR_CURSORLINE_FORCED)
            else
                nvim_set_option_value("cursorlineopt", "number", { win = winid })
                set_window_var(winid, VAR_CURSORLINE_FORCED, true)
            end

            update_window(winid)
        end,
    })

    nvim_create_autocmd("ColorScheme", {
        group = augroup,
        callback = apply_prefix_highlight,
    })
end

local function get_cached_line(width, num, is_cursor)
    local normal_cache, cursor_cache = ensure_width_cache(width)
    local active_cache = is_cursor and cursor_cache or normal_cache
    local formatted = active_cache[num]
    if formatted then
        return formatted
    end

    local normal_line, cursor_line = build_line_pair(width, num)
    normal_cache[num] = normal_line
    cursor_cache[num] = cursor_line
    return is_cursor and cursor_line or normal_line
end

local function render_line(width, lnum, relnum, use_relative)
    local relnum_abs = abs(relnum)
    local is_cursor = relnum_abs == 0
    if not is_cursor and use_relative == 1 then
        lnum = relnum_abs
    end
    return get_cached_line(width, lnum, is_cursor)
end

local function define_formatter()
    _G.FormatLineNr = function(width, use_relative)
        if v.virtnum ~= 0 then
            return ""
        end

        local relnum_abs = abs(v.relnum)
        if relnum_abs == 0 then
            return get_cached_line(width, v.lnum, true)
        end

        local num = use_relative == 1 and relnum_abs or v.lnum
        return get_cached_line(width, num, false)
    end
end

function M._reset_for_tests()
    if augroup then
        pcall(nvim_del_augroup_by_id, augroup)
        augroup = nil
    end
    buf_digit_counts = {}
    normal_line_cache = {}
    cursor_line_cache = {}
    statuscolumn_cache = {}
    vim.g._numberline_loaded = nil
    _G.FormatLineNr = nil
end

M._test = {
    clear_window = clear_window,
    render_line = render_line,
    update_window = update_window,
    update_buffer_windows = update_buffer_windows,
}

function M.setup()
    if vim.g._numberline_loaded then
        return
    end
    vim.g._numberline_loaded = true

    apply_prefix_highlight()
    for width = 1, SEEDED_WIDTH_LIMIT do
        ensure_width_cache(width)
    end
    define_formatter()
    setup_autocmds()

    buf_digit_counts = {}
    for _, winid in ipairs(nvim_list_wins()) do
        update_window(winid)
    end
end

M.setup()

return M
