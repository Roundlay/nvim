if vim.g.vscode then
    return
end

local M = {}

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
        if vim.w._pln_user_cursorlineopt == nil then
            vim.w._pln_user_cursorlineopt = vim.api.nvim_get_option_value("cursorlineopt", { win = winid })
        end
        vim.api.nvim_set_option_value("cursorlineopt", "number", { win = winid })
        vim.api.nvim_set_option_value("cursorline", true, { win = winid })
        vim.w._pln_cursorline_forced = true
    end

    local line_count = vim.api.nvim_buf_line_count(buf)
    local digits = #tostring(line_count)
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

    augroup = vim.api.nvim_create_augroup("PrettyLineNumbers", { clear = true })

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
            local digits = #tostring(count)
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
                local restore = vim.w._pln_user_cursorlineopt or "line,number"
                vim.api.nvim_set_option_value("cursorlineopt", restore, { scope = "global", win = win })
                vim.w._pln_cursorline_forced = false
            else
                vim.api.nvim_set_option_value("cursorlineopt", "number", { scope = "global", win = win })
                vim.w._pln_cursorline_forced = true
            end

            update_window(win)
        end,
    })
end

local function define_formatter()
    _G.FormatLineNr = function(width, use_rel)
        if vim.v.virtnum ~= 0 then
            return ""
        end
        local rel = vim.v.relnum
        local num = (use_rel == 1 and rel ~= 0) and math.abs(rel) or vim.v.lnum
        local hl = (rel == 0) and "CursorLineNr" or "LineNr"
        local padded = ("%0" .. width .. "d"):format(num)
        local zeros, rest = padded:match("^(0*)(.*)$")

        return ("%%#LineNrPrefix#%s%%#%s#%s %%*"):format(zeros, hl, rest)
    end
end

function M.setup()
    if vim.g._pln_loaded then
        return
    end
    vim.g._pln_loaded = true

    buf_digit_counts = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        update_window(win)
    end

    setup_autocmds()
    define_formatter()
end

M.setup()

return M
