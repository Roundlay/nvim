-- TODO: Why doesn't this work in help files?

if vim.g.vscode then
    return
end

local M = {}

-- Upvalue hoisting: reduce table lookups in hot path
local v = vim.v
local abs = math.abs
local tostring = tostring

-- Highlight group name constants (avoid runtime string creation)
local HL_CURSOR = "CursorLineNr"
local HL_NORMAL = "LineNr"

-- Format string parts (pre-computed, immutable)
local FMT_PREFIX = "%#LineNrPrefix#"
local FMT_SUFFIX = " %*"

-- O(1) digit counter via threshold comparison
-- Avoids log10() call and handles edge cases cleanly
local function digit_count(n)
    if n < 10 then return 1 end
    if n < 100 then return 2 end
    if n < 1000 then return 3 end
    if n < 10000 then return 4 end
    if n < 100000 then return 5 end
    if n < 1000000 then return 6 end
    return 7
end

-- Zero-padding strings lookup table: zeros_lut[width][zero_count] = "000..."
-- Pre-computed at module load to avoid runtime string.rep() calls
local zeros_lut = {}
for w = 1, 7 do
    zeros_lut[w] = {}
    for z = 0, w do
        zeros_lut[w][z] = string.rep("0", z)
    end
end

-- Full pre-computation cache: results_cache[width][line_number][is_cursor]
-- Trades ~200KB memory for zero allocations in hot path
local results_cache = {}

-- Fallback formatter for lines beyond cache (rare: files > 10K lines)
local function format_line_uncached(num, hl, width)
    local digits = digit_count(num)
    local zero_count = width - digits
    local zeros = zeros_lut[width] and zeros_lut[width][zero_count] or ""
    return FMT_PREFIX .. zeros .. "%#" .. hl .. "#" .. tostring(num) .. FMT_SUFFIX
end

-- Initialize the full result cache
-- max_width: maximum digit width to cache (5 = up to 99,999 lines)
-- max_lines: maximum line number to cache
local function init_cache(max_width, max_lines)
    for w = 1, max_width do
        results_cache[w] = {}
        for n = 0, max_lines do
            local digits = digit_count(n)
            local zero_count = w - digits
            local zeros = zeros_lut[w] and zeros_lut[w][zero_count] or ""
            local num_str = tostring(n)
            results_cache[w][n] = {
                [true] = FMT_PREFIX .. zeros .. "%#" .. HL_CURSOR .. "#" .. num_str .. FMT_SUFFIX,
                [false] = FMT_PREFIX .. zeros .. "%#" .. HL_NORMAL .. "#" .. num_str .. FMT_SUFFIX,
            }
        end
    end
end

-- Module state
local buf_digit_counts = {}
local augroup = nil

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
    if not vim.api.nvim_win_is_valid(winid) then
        return
    end

    local number_on = vim.api.nvim_win_get_option(winid, "number")
    local rnumber_on = vim.api.nvim_win_get_option(winid, "relativenumber")
    if not number_on and not rnumber_on then
        if vim.api.nvim_win_get_option(winid, "statuscolumn") ~= "" then
            pcall(vim.api.nvim_win_set_option, winid, "statuscolumn", "")
        end
        return
    end

    local buf = vim.api.nvim_win_get_buf(winid)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
    local bt = vim.api.nvim_get_option_value("buftype", { buf = buf })
    if excluded_filetypes[ft] or excluded_buftypes[bt] then
        return
    end

    local cursorline_enabled = vim.api.nvim_get_option_value("cursorline", { scope = "global", win = winid })
    if not cursorline_enabled then
        if vim.w._nl_user_cursorlineopt == nil then
            vim.w._nl_user_cursorlineopt = vim.api.nvim_get_option_value("cursorlineopt", { win = winid })
        end
        vim.api.nvim_set_option_value("cursorlineopt", "number", { win = winid })
        vim.api.nvim_set_option_value("cursorline", true, { win = winid })
        vim.w._nl_cursorline_forced = true
    end

    local line_count = vim.api.nvim_buf_line_count(buf)
    local digits = digit_count(line_count)
    local required_width = math.max(2, digits + 2)

    if vim.api.nvim_win_get_option(winid, "numberwidth") ~= required_width then
        pcall(vim.api.nvim_win_set_option, winid, "numberwidth", required_width)
    end

    local use_relative = vim.api.nvim_win_get_option(winid, "relativenumber") and 1 or 0
    local status_column = string.format("%%!v:lua.FormatLineNr(%d,%d)", digits, use_relative)

    if vim.api.nvim_win_get_option(winid, "statuscolumn") ~= status_column then
        pcall(vim.api.nvim_win_set_option, winid, "statuscolumn", status_column)
    end

    buf_digit_counts[buf] = digits
end

local function setup_autocmds()
    if augroup then
        return
    end

    augroup = vim.api.nvim_create_augroup("Numberline", { clear = true })

    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "WinNew", "WinResized" }, {
        group = augroup,
        callback = function(ev)
            update_window(ev.win)
        end,
    })

    vim.api.nvim_create_autocmd("OptionSet", {
        group = augroup,
        pattern = { "relativenumber", "number" },
        callback = function()
            update_window()
        end,
    })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
        group = augroup,
        callback = function(ev)
            local buf = ev.buf
            if not vim.api.nvim_buf_is_valid(buf) then
                return
            end

            local count = vim.api.nvim_buf_line_count(buf)
            local digits = digit_count(count)
            local cached = buf_digit_counts[buf] or 0

            if digits ~= cached then
                buf_digit_counts[buf] = digits
                for _, window in ipairs(vim.fn.win_findbuf(buf)) do
                    update_window(window)
                end
            end
        end,
    })

    vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "cursorline",
        group = augroup,
        callback = function(ev)
            local win = ev.win
            local now_on = vim.api.nvim_get_option_value("cursorline", { scope = "global", win = win })

            if now_on then
                local restore = vim.w._nl_user_cursorlineopt or "line,number"
                vim.api.nvim_set_option_value("cursorlineopt", restore, { scope = "global", win = win })
                vim.w._nl_cursorline_forced = false
            else
                vim.api.nvim_set_option_value("cursorlineopt", "number", { scope = "global", win = win })
                vim.w._nl_cursorline_forced = true
            end

            update_window(win)
        end,
    })
end

-- Hot path: called per-line during rendering
-- Optimized for zero allocations via pre-computed cache lookup
local function define_formatter()
    _G.FormatLineNr = function(width, use_rel)
        -- Fast path: skip virtual lines (wrapped lines, folds)
        if v.virtnum ~= 0 then
            return ""
        end

        local rel = v.relnum
        local is_cursor = rel == 0
        local num = is_cursor and v.lnum or (use_rel == 1 and abs(rel) or v.lnum)

        -- Cache lookup: O(1) with zero allocations
        local width_cache = results_cache[width]
        if width_cache then
            local num_cache = width_cache[num]
            if num_cache then
                return num_cache[is_cursor]
            end
        end

        -- Fallback for lines beyond cache (files > 10K lines)
        return format_line_uncached(num, is_cursor and HL_CURSOR or HL_NORMAL, width)
    end
end

function M.setup()
    if vim.g._numberline_loaded then
        return
    end
    vim.g._numberline_loaded = true

    -- Initialize pre-computation cache: 5 widths x 10K lines x 2 variants (~200KB)
    init_cache(5, 9999)

    buf_digit_counts = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        update_window(win)
    end

    setup_autocmds()
    define_formatter()
end

M.setup()

return M
