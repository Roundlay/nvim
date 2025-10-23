if vim.g.vscode then
    return
end

-- Helper function to set highlights more easily
local function set_hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

-- Visual Studio Dark inspired tab colors
set_hl("TabLine", { fg = "#969696", bg = "#252526" }) -- Inactive tabs
set_hl("TabLineFill", { bg = "#1E1E1E" }) -- Tab line background
set_hl("TabLineSel", { fg = "#FFFFFF", bg = "#68217A", bold = true }) -- Active tab (iconic VS purple)

-- Line number highlights
set_hl("LineNr", { fg = "#7d7d7d", ctermfg = 244 })
set_hl("CursorLineNr", { fg = "#ffffff", ctermfg = 15, bold = true })
set_hl("LineNrPrefix", { fg = "#404040", ctermfg = 238 })

-- Custom Virtual Diagnostic Highlights
set_hl("CustomDiagText", { fg = "#f00823", bg = "#360714" })
set_hl("CustomDiagLine", { bg = "#5a1f1f" })

-- Window divider highlights for narrow unfocused windows
set_hl("VertSplit", { fg = "#68217A", bg = "NONE", bold = true })  -- Purple divider
set_hl("WinSeparator", { fg = "#68217A", bg = "NONE", bold = true })  -- For newer Neovim versions

-- Indentation and braces
-- set_hl("IndentBlanklineChar", { fg = "#3d3d3d" })

-- Checkbox tokens across todo-heavy notes; batching them keeps this lean on CPU.
local todo_patterns = {
    { pattern = "\\[\\]", hl_group = "TodoPattern" },
    { pattern = "\\[ \\]", hl_group = "TodoPattern" },
    { pattern = "\\[+\\]", hl_group = "TodoPattern" },
    { pattern = "\\[X\\]", hl_group = "TodoComplete" },
    { pattern = "\\[x\\]", hl_group = "TodoComplete" },
    { pattern = "\\[?\\]", hl_group = "TodoAmbiguous" },
    { pattern = "\\[>\\]", hl_group = "TodoAmbiguous" },
    { pattern = "\\[<\\]", hl_group = "TodoAmbiguous" },
    { pattern = "\\[!\\]", hl_group = "TodoAlert" },
    { pattern = "\\[/\\]", hl_group = "TodoAlert" },
    { pattern = "\\[@\\]", hl_group = "TodoSpecial" },
    { pattern = "\\[\\~\\]", hl_group = "TodoSpecial" },
    { pattern = "\\[-\\]", hl_group = "TodoDropped" },
}

-- Paint palette for the checkbox states; set once, refresh on colorscheme swaps.
local todo_highlights = {
    { name = "TodoPattern", opts = { fg = "#7fb4ca", bold = true } },
    { name = "TodoComplete", opts = { fg = "#40df65", bold = true } },
    { name = "TodoAlert", opts = { fg = "#df4540", bold = true } },
    { name = "TodoMiddle", opts = { fg = "#df6540", bold = true } },
    { name = "TodoAmbiguous", opts = { fg = "#6540df", bold = true } },
    { name = "TodoSpecial", opts = { fg = "#d7ba7d", bold = true } },
    { name = "TodoDropped", opts = { fg = "#5a5a5a", bold = true } },
    { name = "@markup.link", opts = { fg = "#7fb4ca", bold = true, underline = false } },
    { name = "@markup.list.checked.markdown", opts = { fg = "#7fb4ca", bold = true, underline = false } },
    { name = "@markup.list.unchecked.markdown", opts = { fg = "#7fb4ca", bold = true, underline = false } },
}

-- There is no caching here—reapply the palette any time we're asked.
local function apply_todo_highlights()
    for _, hl in ipairs(todo_highlights) do
        set_hl(hl.name, hl.opts)
    end
end

apply_todo_highlights()

-- Track which windows already carry checkbox matches so we never duplicate work.
local todo_match_ids = {}
local todo_match_lookup = {}
for _, entry in ipairs(todo_patterns) do
    todo_match_lookup[entry.hl_group] = true
end

local function delete_existing_todo_matches(win)
    local ok, existing = pcall(vim.fn.getmatches, win)
    if not ok then
        return
    end
    for _, match in ipairs(existing) do
        if todo_match_lookup[match.group] then
            pcall(vim.fn.matchdelete, match.id, win)
        end
    end
end

local function ensure_todo_matches(win)
    if win == nil or todo_match_ids[win] or not vim.api.nvim_win_is_valid(win) then
        return
    end

    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative ~= "" then
        return
    end

    -- Clear any leftovers first; users restart faster than Vim clears matches.
    delete_existing_todo_matches(win)

    local matches = {}
    for _, entry in ipairs(todo_patterns) do
        local id = vim.fn.matchadd(entry.hl_group, entry.pattern, 10, -1, { window = win })
        if id >= 0 then
            matches[#matches + 1] = id
        end
    end

    if #matches > 0 then
        todo_match_ids[win] = matches
    end
end

local function clear_todo_matches(win)
    local matches = todo_match_ids[win]
    if not matches then
        delete_existing_todo_matches(win)
        return
    end
    for _, id in ipairs(matches) do
        pcall(vim.fn.matchdelete, id, win)
    end
    todo_match_ids[win] = nil
    delete_existing_todo_matches(win)
end

local todo_group = vim.api.nvim_create_augroup("TodoCheckboxHighlights", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
    group = todo_group,
    callback = apply_todo_highlights,
})

vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter" }, {
    group = todo_group,
    callback = function(args)
        ensure_todo_matches(args.win or vim.api.nvim_get_current_win())
    end,
})

vim.api.nvim_create_autocmd("WinClosed", {
    group = todo_group,
    callback = function(args)
        local win = tonumber(args.match)
        if win then
            clear_todo_matches(win)
        end
    end,
})

for _, win in ipairs(vim.api.nvim_list_wins()) do
    ensure_todo_matches(win)
end
