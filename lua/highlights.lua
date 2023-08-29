-- highlights.lua

-- local fuji_white = "#DCD7BA"
local sumi_ink_2 = "#2A2A37"

-- NOTE: It's so stupid that I have to do this.
NONE = NONE

vim.api.nvim_set_hl(0, "LineNr", {fg = sumi_ink_2, bg = NONE, gui = NONE})

-- TODO Highlight doesn't apply when set with vim.api.nvim_set_hl...

vim.cmd [[ highlight WinSeparator guifg=bg guibg=bg cterm=NONE ]]

vim.api.nvim_set_hl(0, "@procOpeningBrace",        {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@procClosingBrace",        {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@forOpeningBrace",         {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@forClosingBrace",         {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@forAssignmentSemicolon",  {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@ifStatementOpeningBrace", {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@ifStatementClosingBrace", {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@elseClauseOpeningBrace",  {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@elseClauseClosingBrace",  {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@forStatementSemicolon",   {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@switchOpeningBrace",      {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@switchClosingBrace",      {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@structOpeningBrace",      {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@structClosingBrace",      {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@foreignOpeningBrace",     {fg = sumi_ink_2})
vim.api.nvim_set_hl(0, "@foreignClosingBrace",     {fg = sumi_ink_2})

-- TODO: Figure out a way to check which theme is currently active so that
-- you can set the indent blankline colours to match dynamically.

vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = "#252535"}) -- Kanagawa
