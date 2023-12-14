-- highlights.lua

if vim.g.vscode then
    return
end

-- local fuji_white = "#DCD7BA"
local sumi_ink_2 = "#2A2A37"
local winter_blue = "#252535"
local sumiInk3 = "#363646"
local sumiInk4 = "#54546D"

-- NOTE: It's so stupid that I have to do this.
NONE = NONE

vim.api.nvim_set_hl(0, "LineNr", {fg = sumi_ink_2, bg = NONE, gui = NONE})

vim.cmd [[ highlight WinSeparator guifg=bg guibg=bg cterm=NONE ]]

vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = "#252535"}) -- Kanagawa

vim.api.nvim_set_hl(0, "@curlybraces", {fg = sumiInk3})

-- vim.api.nvim_set_hl(0, "@procOpeningBrace",        {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@procClosingBrace",        {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@forOpeningBrace",         {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@forClosingBrace",         {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@forAssignmentSemicolon",  {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@ifStatementOpeningBrace", {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@ifStatementClosingBrace", {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@elseClauseOpeningBrace",  {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@elseClauseClosingBrace",  {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@forStatementSemicolon",   {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@switchOpeningBrace",      {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@switchClosingBrace",      {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@structOpeningBrace",      {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@structClosingBrace",      {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@enumOpeningBrace",        {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@enumClosingBrace",        {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@foreignOpeningBrace",     {fg = sumiInk3})
-- vim.api.nvim_set_hl(0, "@foreignClosingBrace",     {fg = sumiInk3})
