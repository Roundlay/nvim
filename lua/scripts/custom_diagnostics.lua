if vim.g.vscode then
    return
end

local M = {}

-- TODO FEATURE Don't display diagnostics if the file has been modified but not saved.
-- TODO: Occasionally, diagnostics aren't cleared up properly, and they remain in place, often at the end of the file, even after the offending code has been removed.

-- TODO: Rename namespace
local ns = vim.api.nvim_create_namespace("custom_diagnostics")

local MAX_BANNERS_PER_LINE = 3
local provider = {}
local enabled = false
local autocmd_group = nil

local function render(_, win, buf, topline, botline)
    vim.api.nvim_buf_clear_namespace(buf, ns, topline, botline + 1)

    local errs = vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
    if #errs == 0 then
        return
    end

    local grouped = {}
    for _, d in ipairs(errs) do
        if d.lnum >= topline and d.lnum <= botline then
            grouped[d.lnum] = grouped[d.lnum] or {}
            table.insert(grouped[d.lnum], d)
        end
    end

    if next(grouped) == nil then
        return
    end

    local win_width = vim.api.nvim_win_get_width(win)

    for lnum, diags in pairs(grouped) do
        local text = vim.api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1] or ""
        local indent = #text:match("^[\t ]*")

        local prefix = (" "):rep(indent)
        local avail = math.max(1, win_width - indent)

        local virt_lines = {}

        for i = 1, math.min(MAX_BANNERS_PER_LINE, #diags) do
            local msg = diags[i].message:gsub("[%s\r\n]+", " "):gsub("%s+$", "")
            if vim.fn.strdisplaywidth(msg) > avail then
                msg = msg:sub(1, avail - 1) .. "…"
            end

            local line = prefix .. msg
            local pad = win_width - vim.fn.strdisplaywidth(line)
            if pad > 0 then
                line = line .. (" "):rep(pad)
            end

            table.insert(virt_lines, { { line, "CustomDiagText" } })
        end

        local hidden = #diags - MAX_BANNERS_PER_LINE
        if hidden > 0 then
            local msg = prefix .. string.format("… %d more error%s truncated …", hidden, hidden == 1 and "" or "s")
            local pad = win_width - vim.fn.strdisplaywidth(msg)
            if pad > 0 then
                msg = msg .. (" "):rep(pad)
            end

            table.insert(virt_lines, { { msg, "CustomDiagText" } })
        end

        vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
            virt_lines = virt_lines,
            virt_lines_above = true,
            line_hl_group = "CustomDiagLine",
            hl_mode = "combine",
            priority = 1,
        })
    end
end

local function enable()
    if enabled then
        return
    end
    vim.api.nvim_set_decoration_provider(ns, provider)
    enabled = true
end

local function disable()
    if not enabled then
        return
    end
    vim.api.nvim_set_decoration_provider(ns, {})
    enabled = false
end

local function setup_autocmds()
    if autocmd_group then
        return
    end

    autocmd_group = vim.api.nvim_create_augroup("CustomDiagnosticsFormatter", { clear = true })

    vim.api.nvim_create_autocmd("InsertEnter", {
        group = autocmd_group,
        callback = disable,
    })

    vim.api.nvim_create_autocmd("InsertLeave", {
        group = autocmd_group,
        callback = function()
            enable()
            vim.schedule(function()
                vim.diagnostic.show(nil, 0)
                vim.cmd("redraw!")
            end)
        end,
    })

    vim.api.nvim_create_autocmd("DiagnosticChanged", {
        group = autocmd_group,
        callback = function(args)
            vim.schedule(function()
                for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
                    vim.api.nvim_win_call(win, function()
                        vim.cmd("redraw!")
                    end)
                end
            end)
        end,
    })
end

function M.setup()
    if vim.g._custom_diag_loaded then
        return M
    end
    vim.g._custom_diag_loaded = true

    provider.on_win = render

    vim.diagnostic.config({
        virtual_text = false,
        virtual_lines = false,
        underline = false,
        signs = false,
        update_in_insert = false,
    })

    setup_autocmds()
    enable()

    return M
end

function M.enable()
    enable()
end

function M.disable()
    disable()
end

M.setup()

return M
