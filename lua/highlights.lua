-- highlights.lua

-- ========================================================================== --
-- Kanagawa Colours
-- ========================================================================== --

local background = "#1f1f28"
local fg = "#dcd7ba"
local fujiWhite = "#DCD7BA"
local fujiGray = "#727169"
local sumiInk2 = "#2A2A37"
local sumiInk4 = "#54546D"
local waveBlue2 = "#2D4F67"
local winterRed = "#43242B"
local winterBlue = "#252535"
local winterYellow = "#49443C"
local winterGreen = "#2B3328"
local oniViolet = "#957FB8"
local black = "#090618"
local red = "#c34043"
local green = "#76946a"
local yellow = "#c0a36e"
local blue = "#7e9cd8"
local magenta = "#957fb8"
local cyan = "#6a9589"
local white = "#c8c093"
local bright_black = "#727169"
local bright_red = "#e82424"
local bright_green = "#98bb6c"
local bright_yellow = "#e6c384"
local bright_blue = "#7fb4ca"
local bright_magenta = "#938aa9"
local bright_cyan = "#7aa89f"
local bright_white = "#dcd7ba"
local selection_background = "#2d4f67"
local selection_foreground = "#c8c093"

if vim.g.vscode then

    -- ...

else

    vim.api.nvim_set_hl(0, "LineNr", {fg = sumiInk2, bg = NONE, gui = NONE})

    -- Mini
    -- ---------------------------------------------------------------------- --

    -- vim.api.nvim_set_hl(0, "MiniCursorword", {fg = NONE, underline = true})
    -- vim.api.nvim_set_hl(0, "MiniCursorwordCurrent", {fg = NONE, underline = false,})
    -- vim.api.nvim_set_hl(0, "MiniTrailspace", {fg = bright_cyan, bg = blue})

    -- Treesitter
    -- ---------------------------------------------------------------------- --

    vim.api.nvim_set_hl(0, "@procOpeningBrace",          {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@procClosingBrace",          {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedOpeningBrace",        {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedClosingBrace",        {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedIfTrueOpeningBrace",  {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedIfTrueClosingBrace",  {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedIfFalseOpeningBrace", {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedIfFalseClosingBrace", {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@forStatementSemicolon",     {fg = oniViolet})

    -- Todos
    -- ---------------------------------------------------------------------- --

    -- vim.cmd [[ highlight Todo guifg=#FFFFFF guibg=bg gui=bold cterm=bold ]]
    -- vim.api.nvim_set_hl(0, "Todo", {fg = kanagawa_white, bg = kanagawa_bg, bold=true})

    -- Nvim Tree
    -- ---------------------------------------------------------------------- --

    -- vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", {fg = background})

    -- Indent-Blankline
    -- ---------------------------------------------------------------------- --

    -- TODO: Figure out a way to check which theme is currently active so that
    -- you can set the indent blankline colours to match the theme.

    vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = "#252535"}) -- Kanagawa
    -- vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = "#252535"}) -- Code Dark

    -- Quick Scope
    -- ---------------------------------------------------------------------- --

    vim.api.nvim_set_hl(0, "QuickScopePrimary", {fg = "#FF00FF", bold = true, blend = 100})
    vim.api.nvim_set_hl(0, "QuickScopeSecondary", {fg = "#00FF00", bold = false, blend = 50})

end
