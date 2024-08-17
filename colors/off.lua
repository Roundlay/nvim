-- off.lua: A Neovim colorscheme inspired by a more pleasant version of `syntax off`

-- TODOs:

-- Add highlights for the following:
-- 'LeapBackdrop'
-- "LineNr"
-- "IndentBlanklineChar"
-- "@curlybraces"
-- 'SearchCounterDim'

local M = {}

-- Helper function to set highlights
local function highlight(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

vim.g.colors_name = "off"
local colors_off_a_little = vim.g.colors_off_a_little or false

if vim.g.colors_name then
    vim.cmd("hi clear")
    if vim.fn.exists("syntax_on") then
        vim.cmd("syntax reset")
    end
end

-- Color definitions
local colors = {
    black           = "#212121",
    medium_gray     = "#767676",
    white           = "#F1F1F1",
    actual_white    = "#FFFFFF",
    light_black     = "#424242",
    lighter_black   = "#545454",
    subtle_black    = "#303030",
    light_gray      = "#B2B2B2",
    lighter_gray    = "#C6C6C6",
    subtle_gray     = "#696969",
    pink            = "#fb007a",
    dark_red        = "#C30771",
    light_red       = "#E32791",
    orange          = "#D75F5F",
    darker_blue     = "#005F87",
    dark_blue       = "#008EC4",
    blue            = "#20BBFC",
    light_blue      = "#b6d6fd",
    dark_cyan       = "#20A5BA",
    light_cyan      = "#4FB8CC",
    dark_green      = "#10A778",
    light_green     = "#5FD7A7",
    dark_purple     = "#523C79",
    light_purple    = "#6855DE",
    yellow          = "#F3E430",
    dark_yellow     = "#A89C14",
}

-- Set color palette based on background
local background, bg_subtle, bg_subtle_comment, bg_very_subtle, norm, norm_subtle, purple, cyan, green, red, visual

if vim.o.background == "dark" then
    background = colors.black
    bg_subtle = colors.light_black
    bg_subtle_comment = colors.subtle_gray
    bg_very_subtle = colors.subtle_black
    norm = colors.lighter_gray
    norm_subtle = colors.light_gray
    purple = colors.light_purple
    cyan = colors.light_cyan
    green = colors.light_green
    red = colors.light_red
    visual = colors.lighter_black
else
    background = colors.actual_white
    bg_subtle = colors.light_gray
    bg_subtle_comment = colors.subtle_gray
    bg_very_subtle = colors.lighter_gray
    norm = colors.light_black
    norm_subtle = colors.lighter_black
    purple = colors.dark_purple
    cyan = colors.dark_cyan
    green = colors.dark_green
    red = colors.dark_red
    visual = colors.light_blue
end

-- Set highlights
highlight("Normal", { background = background, fg = norm })
highlight("Cursor", { background = colors.blue, fg = norm })
highlight("Comment", { fg = bg_subtle_comment, italic = true })

-- Link similar highlight groups
local links = {
    {"Constant", "Normal"},
    {"Character", "Constant"},
    {"Number", "Constant"},
    {"Boolean", "Constant"},
    {"Float", "Constant"},
    {"String", "Constant"},
    {"Identifier", "Normal"},
    {"Function", "Identifier"},
    {"Statement", "Normal"},
    {"Conditional", "Statement"},
    {"Repeat", "Statement"},
    {"Label", "Statement"},
    {"Operator", "Statement"},
    {"Keyword", "Statement"},
    {"Exception", "Statement"},
    {"PreProc", "Normal"},
    {"Include", "PreProc"},
    {"Define", "PreProc"},
    {"Macro", "PreProc"},
    {"PreCondit", "PreProc"},
    {"Type", "Normal"},
    {"StorageClass", "Type"},
    {"Structure", "Type"},
    {"Typedef", "Type"},
    {"Special", "Normal"},
    {"SpecialChar", "Special"},
    {"Tag", "Special"},
    {"Delimiter", "Special"},
    {"SpecialComment", "Special"},
    {"Debug", "Special"},
}

for _, link in ipairs(links) do
    vim.api.nvim_set_hl(0, link[1], { link = link[2] })
end

-- Set other highlights
highlight("Underlined", { fg = norm, underline = true })
highlight("Ignore", { fg = background })
highlight("Error", { fg = colors.actual_white, background = red, bold = true })
highlight("Todo", { fg = colors.actual_white, background = colors.pink, bold = true })
highlight("SpecialKey", { fg = colors.light_green })
highlight("NonText", { fg = colors.medium_gray })
highlight("Directory", { fg = colors.dark_blue })
highlight("ErrorMsg", { fg = colors.pink })
highlight("IncSearch", { background = colors.yellow, fg = colors.light_black })
highlight("Search", { background = bg_subtle, fg = norm })
highlight("MoreMsg", { fg = colors.medium_gray, bold = true })
highlight("ModeMsg", { link = "MoreMsg" })
highlight("LineNr", { fg = bg_subtle })
highlight("CursorLineNr", { fg = colors.blue, background = bg_very_subtle })
highlight("Question", { fg = red })
highlight("StatusLine", { background = bg_very_subtle })
highlight("StatusLineNC", { background = bg_very_subtle, fg = colors.medium_gray })
highlight("VertSplit", { background = bg_very_subtle, fg = bg_very_subtle })
highlight("Title", { fg = colors.dark_blue })
highlight("Visual", { background = visual })
highlight("VisualNOS", { background = bg_subtle })
highlight("WarningMsg", { fg = red })
highlight("WildMenu", { fg = background, background = norm })
highlight("Folded", { fg = colors.medium_gray })
highlight("FoldColumn", { fg = bg_subtle })
highlight("DiffAdd", { fg = green })
highlight("DiffDelete", { fg = red })
highlight("DiffChange", { fg = colors.dark_yellow })
highlight("DiffText", { fg = colors.dark_blue })
highlight("SignColumn", { fg = colors.light_green })

-- Set spell highlights
if vim.fn.has("gui_running") == 1 then
    highlight("SpellBad", { undercurl = true, sp = red })
    highlight("SpellCap", { undercurl = true, sp = colors.light_green })
    highlight("SpellRare", { undercurl = true, sp = colors.pink })
    highlight("SpellLocal", { undercurl = true, sp = colors.dark_green })
else
    highlight("SpellBad", { underline = true, fg = red })
    highlight("SpellCap", { underline = true, fg = colors.light_green })
    highlight("SpellRare", { underline = true, fg = colors.pink })
    highlight("SpellLocal", { underline = true, fg = colors.dark_green })
end

-- Set other UI element highlights
highlight("Pmenu", { fg = norm, background = bg_subtle })
highlight("PmenuSel", { fg = norm, background = colors.blue })
highlight("PmenuSbar", { fg = norm, background = bg_subtle })
highlight("PmenuThumb", { fg = norm, background = bg_subtle })
highlight("TabLine", { fg = norm, background = bg_very_subtle })
highlight("TabLineSel", { fg = colors.blue, background = bg_subtle, bold = true })
highlight("TabLineFill", { fg = norm, background = bg_very_subtle })
highlight("CursorColumn", { background = bg_very_subtle })
highlight("CursorLine", { fg = norm, background = bg_very_subtle })
highlight("ColorColumn", { background = bg_subtle })
highlight("MatchParen", { background = bg_subtle, fg = norm })
highlight("qfLineNr", { fg = colors.medium_gray })

-- HTML highlights
for i = 1, 6 do
    highlight("htmlH" .. i, { background = background, fg = norm })
end

-- Link diff highlights
vim.api.nvim_set_hl(0, "diffRemoved", { link = "DiffDelete" })
vim.api.nvim_set_hl(0, "diffAdded", { link = "DiffAdd" })

-- Signify, git-gutter
vim.api.nvim_set_hl(0, "SignifySignAdd", { link = "LineNr" })
vim.api.nvim_set_hl(0, "SignifySignDelete", { link = "LineNr" })
vim.api.nvim_set_hl(0, "SignifySignChange", { link = "LineNr" })

if colors_off_a_little then
    highlight("GitGutterAdd", { fg = colors.dark_green })
    highlight("GitGutterChange", { fg = colors.dark_yellow })
    highlight("GitGutterDelete", { fg = colors.dark_red })
    highlight("GitGutterChangeDelete", { fg = colors.dark_red })
else
    vim.api.nvim_set_hl(0, "GitGutterAdd", { link = "LineNr" })
    vim.api.nvim_set_hl(0, "GitGutterDelete", { link = "LineNr" })
    vim.api.nvim_set_hl(0, "GitGutterChange", { link = "LineNr" })
    vim.api.nvim_set_hl(0, "GitGutterChangeDelete", { link = "LineNr" })
end

-- Fuzzy Search, Telescope & CtrlP
if colors_off_a_little then
    highlight("CtrlPMatch", { fg = colors.light_green, bold = true })
    highlight("TelescopeMatching", { fg = colors.light_green, background = colors.subtle_black })
    highlight("TelescopeSelection", { background = colors.subtle_black, bold = true })
else
    highlight("CtrlPMatch", { bold = true })
    highlight("TelescopeMatching", {})
    highlight("TelescopeSelection", { background = colors.subtle_black, bold = true })
end

return M
