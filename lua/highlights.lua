-- highlights.lua

if vim.g.vscode then

    vim.api.nvim_set_hl(0, "QuickScopePrimary",   {fg = "#FF00FF", bold = 0})
    vim.api.nvim_set_hl(0, "QuickScopeSecondary", {fg = "#00FF00", bold = 1})
    return

end

-- -------------------------------------------------------------------------- --

local kanagawa  = require("kanagawa.colors").setup().theme
local fujiWhite = "#DCD7BA"
local sumiInk2  = "#2A2A37"

-- TODO How can the `Undefined global `NONE`` error be remedied.
vim.api.nvim_set_hl(0, "LineNr", {fg = sumiInk2, bg = NONE, gui = NONE})

-- TODO Highlight doesn't apply when set with vim.api.nvim_set_hl...
vim.cmd [[ highlight WinSeparator guifg=bg guibg=bg cterm=NONE ]]

vim.api.nvim_set_hl(0, "Pmenu",      { fg = kanagawa.ui.shade0, bg = kanagawa.ui.bg_p1})
vim.api.nvim_set_hl(0, "PmenuSel",   { fg = "NONE", bg = kanagawa.ui.bg_p2 })
vim.api.nvim_set_hl(0, "PmenuSbar",  { bg = kanagawa.ui.bg_m1 })
vim.api.nvim_set_hl(0, "PmenuThumb", { bg = kanagawa.ui.bg_p2 })

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
vim.api.nvim_set_hl(0, "@structOpeningBrace",           {fg = sumiInk2})
vim.api.nvim_set_hl(0, "@structClosingBrace",           {fg = sumiInk2})

vim.api.nvim_set_hl(0, "Todo", {fg = fujiWhite, bg = bg, bold=true})

-- vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", {fg = background})

-- TODO: Figure out a way to check which theme is currently active so that you can set the indent blankline colours to match dynamically.

vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = "#252535"}) -- Kanagawa
-- vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = "#252535"}) -- Code Dark

vim.api.nvim_set_hl(0, "QuickScopePrimary",   {fg = "#FF00FF", bold = true, blend = 100})
vim.api.nvim_set_hl(0, "QuickScopeSecondary", {fg = "#00FF00", bold = false, blend = 50})
