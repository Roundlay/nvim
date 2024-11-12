local M = {}

-- Helper function to set highlights
local function highlight(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
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

local function setup()
    -- Check if colors should be off a little
    local colors_off_a_little = vim.g.colors_off_a_little or false

    -- Set color palette based on background
    local bg, bg_subtle, bg_subtle_comment, bg_very_subtle, norm, norm_subtle, purple, cyan, green, red, visual

    if vim.o.background == "dark" then
        bg = colors.black
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
        bg = colors.actual_white
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

    -- Clear existing highlights
    vim.cmd("highlight clear")
    if vim.fn.exists("syntax_on") then
        vim.cmd("syntax reset")
    end

    -- Set colorscheme name
    vim.g.colors_name = "off"

    -- Define highlights
    highlight("Normal", { fg = norm, bg = bg })
    highlight("Cursor", { fg = norm, bg = colors.blue })
    highlight("Comment", { fg = bg_subtle_comment, italic = true })

    -- Link common groups
    local groups_to_link = {
        "Constant", "Character", "Number", "Boolean", "Float", "String",
        "Identifier", "Function",
        "Statement", "Conditional", "Repeat", "Label", "Operator", "Keyword", "Exception",
        "PreProc", "Include", "Define", "Macro", "PreCondit",
        "Type", "StorageClass", "Structure", "Typedef",
        "Special", "SpecialChar", "Tag", "Delimiter", "SpecialComment", "Debug"
    }

    for _, group in ipairs(groups_to_link) do
        vim.api.nvim_set_hl(0, group, { link = "Normal" })
    end

    -- Set other highlights
    highlight("Underlined", { fg = norm, underline = true })
    highlight("Ignore", { fg = bg })
    highlight("Error", { fg = colors.actual_white, bg = red, bold = true })
    highlight("Todo", { fg = colors.actual_white, bg = colors.pink, bold = true })
    highlight("SpecialKey", { fg = colors.light_green })
    highlight("NonText", { fg = colors.medium_gray })
    highlight("Directory", { fg = colors.dark_blue })
    highlight("ErrorMsg", { fg = colors.pink })
    highlight("IncSearch", { fg = colors.light_black, bg = colors.yellow })
    highlight("Search", { fg = norm, bg = bg_subtle })
    highlight("MoreMsg", { fg = colors.medium_gray, bold = true })
    highlight("ModeMsg", { link = "MoreMsg" })
    highlight("LineNr", { fg = bg_subtle })
    highlight("CursorLineNr", { fg = colors.blue, bg = bg_very_subtle })
    highlight("Question", { fg = red })
    highlight("StatusLine", { bg = bg_very_subtle })
    highlight("StatusLineNC", { fg = colors.medium_gray, bg = bg_very_subtle })
    highlight("VertSplit", { fg = bg_very_subtle, bg = bg_very_subtle })
    highlight("Title", { fg = colors.dark_blue })
    highlight("Visual", { bg = visual })
    highlight("VisualNOS", { bg = bg_subtle })
    highlight("WarningMsg", { fg = red })
    highlight("WildMenu", { fg = bg, bg = norm })
    highlight("Folded", { fg = colors.medium_gray })
    highlight("FoldColumn", { fg = bg_subtle })
    highlight("DiffAdd", { fg = green })
    highlight("DiffDelete", { fg = red })
    highlight("DiffChange", { fg = colors.dark_yellow })
    highlight("DiffText", { fg = colors.dark_blue })
    highlight("SignColumn", { fg = colors.light_green })

    -- Spelling
    highlight("SpellBad", { undercurl = true, sp = red })
    highlight("SpellCap", { undercurl = true, sp = colors.light_green })
    highlight("SpellRare", { undercurl = true, sp = colors.pink })
    highlight("SpellLocal", { undercurl = true, sp = colors.dark_green })

    -- Popup Menu
    highlight("Pmenu", { fg = norm, bg = bg_subtle })
    highlight("PmenuSel", { fg = norm, bg = colors.blue })
    highlight("PmenuSbar", { fg = norm, bg = bg_subtle })
    highlight("PmenuThumb", { fg = norm, bg = bg_subtle })

    -- Tabs
    highlight("TabLine", { fg = norm, bg = bg_very_subtle })
    highlight("TabLineSel", { fg = colors.blue, bg = bg_subtle, bold = true })
    highlight("TabLineFill", { fg = norm, bg = bg_very_subtle })

    -- Cursor
    highlight("CursorColumn", { bg = bg_very_subtle })
    highlight("CursorLine", { bg = bg_very_subtle })
    highlight("ColorColumn", { bg = bg_subtle })

    -- Misc
    highlight("MatchParen", { fg = norm, bg = bg_subtle })
    highlight("qfLineNr", { fg = colors.medium_gray })

    -- HTML headers
    for i = 1, 6 do
        highlight("htmlH" .. i, { fg = norm, bg = bg })
    end

    -- Diffs
    highlight("diffRemoved", { link = "DiffDelete" })
    highlight("diffAdded", { link = "DiffAdd" })

    -- Signify, git-gutter
    highlight("SignifySignAdd", { link = "LineNr" })
    highlight("SignifySignDelete", { link = "LineNr" })
    highlight("SignifySignChange", { link = "LineNr" })

    if colors_off_a_little then
        highlight("GitGutterAdd", { fg = colors.dark_green })
        highlight("GitGutterChange", { fg = colors.dark_yellow })
        highlight("GitGutterDelete", { fg = colors.dark_red })
        highlight("GitGutterChangeDelete", { fg = colors.dark_red })
    else
        highlight("GitGutterAdd", { link = "LineNr" })
        highlight("GitGutterDelete", { link = "LineNr" })
        highlight("GitGutterChange", { link = "LineNr" })
        highlight("GitGutterChangeDelete", { link = "LineNr" })
    end

    -- Fuzzy Search, Telescope & CtrlP
    if colors_off_a_little then
        highlight("CtrlPMatch", { fg = colors.light_green, bold = true })
        highlight("TelescopeMatching", { fg = colors.light_green, bg = colors.subtle_black })
        highlight("TelescopeSelection", { bg = colors.subtle_black, bold = true })
    else
        highlight("CtrlPMatch", { bold = true })
        highlight("TelescopeMatching", {})
        highlight("TelescopeSelection", { bg = colors.subtle_black, bold = true })
    end
end

function M.colorscheme()
    setup()
end

return M
