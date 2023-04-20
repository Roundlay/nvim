-- highlights.lua

-- Kanagawa Colours

local kanagawa = require("kanagawa.colors").setup().theme

local fujiWhite = "#DCD7BA"
local sumiInk2 = "#2A2A37"

if vim.g.vscode then

    -- ...

else

    -- Neovim
    -- ---------------------------------------------------------------------- --

    vim.api.nvim_set_hl(0, "LineNr", {fg = kanagawa.sumiInk2, bg = NONE, gui = NONE})
    vim.cmd [[ highlight WinSeparator guifg=bg guibg=bg cterm=NONE ]]

    -- Kanagawa-styled Popups

    vim.api.nvim_set_hl(0, "Pmenu",      { fg = kanagawa.ui.shade0, bg = kanagawa.ui.bg_p1})
    vim.api.nvim_set_hl(0, "PmenuSel",   { fg = "NONE", bg = kanagawa.ui.bg_p2 })
    vim.api.nvim_set_hl(0, "PmenuSbar",  { bg = kanagawa.ui.bg_m1 })
    vim.api.nvim_set_hl(0, "PmenuThumb", { bg = kanagawa.ui.bg_p2 })

    -- Custom Treesitter Highlights for Odin
    -- ---------------------------------------------------------------------- --

    -- These dim braces and semicolons in Odin files.
    -- Could probably do with a refactor to make it more DRY. <- Copilot.

    vim.api.nvim_set_hl(0, "@procOpeningBrace",             {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@procClosingBrace",             {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedOpeningBrace",           {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedClosingBrace",           {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedIfTrueOpeningBrace",     {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedIfTrueClosingBrace",     {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedIfFalseOpeningBrace",    {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@nestedIfFalseClosingBrace",    {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@forStatementSemicolon",        {fg = sumiInk2})
    vim.api.nvim_set_hl(0, "@switchStatement",              {fg = sumiInk2})

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
    -- you can set the indent blankline colours to match dynamically.

    vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = "#252535"}) -- Kanagawa
    -- vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = "#252535"}) -- Code Dark

    -- Quick Scope
    -- ---------------------------------------------------------------------- --

    vim.api.nvim_set_hl(0, "QuickScopePrimary", {fg = "#FF00FF", bold = true, blend = 100})
    vim.api.nvim_set_hl(0, "QuickScopeSecondary", {fg = "#00FF00", bold = false, blend = 50})

end
