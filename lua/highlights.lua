-- highlights.lua

-- local fuji_white = "#DCD7BA"
local sumi_ink_2 = "#2A2A37"

-- TODO: What's up with the 'Undefined global variable `NONE`' warning?
-- NOTE: It's so stupid that I have to do this.
NONE = NONE

vim.api.nvim_set_hl(0, "LineNr", {fg = sumi_ink_2, bg = NONE, gui = NONE})

-- TODO Highlight doesn't apply when set with vim.api.nvim_set_hl...

vim.cmd [[ highlight WinSeparator guifg=bg guibg=bg cterm=NONE ]]

-- NOTE: tree-sitter-odin is a pain in the ass so opening and closing brace
-- dimming are on hold for the time being.

-- vim.api.nvim_set_hl(0, "@procOpeningBrace",          {fg = sumi_ink_2})
-- vim.api.nvim_set_hl(0, "@procClosingBrace",          {fg = sumi_ink_2})
-- vim.api.nvim_set_hl(0, "@nestedOpeningBrace",        {fg = sumi_ink_2})
-- vim.api.nvim_set_hl(0, "@nestedClosingBrace",        {fg = sumi_ink_2})
-- vim.api.nvim_set_hl(0, "@nestedIfTrueOpeningBrace",  {fg = sumi_ink_2})
-- vim.api.nvim_set_hl(0, "@nestedIfTrueClosingBrace",  {fg = sumi_ink_2})
-- vim.api.nvim_set_hl(0, "@nestedIfFalseOpeningBrace", {fg = sumi_ink_2})
-- vim.api.nvim_set_hl(0, "@nestedIfFalseClosingBrace", {fg = sumi_ink_2})
-- vim.api.nvim_set_hl(0, "@forStatementSemicolon",     {fg = sumi_ink_2})
-- vim.api.nvim_set_hl(0, "@switchStatement",           {fg = sumi_ink_2})
-- vim.api.nvim_set_hl(0, "@structOpeningBrace",        {fg = sumi_ink_2})
-- vim.api.nvim_set_hl(0, "@structClosingBrace",        {fg = sumi_ink_2})

-- TODO: Figure out a way to check which theme is currently active so that
-- you can set the indent blankline colours to match dynamically.

vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = "#252535"}) -- Kanagawa
-- vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = "#252535"}) -- Code Dark
