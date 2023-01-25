-- TODO: Padding around windows needs to be configurable.
-- TODO: A line separator between windows would be nice, but currently it appears offset with the background colour of the active buffer. Find out why this is happening.
-- TODO: Highlighting for **task lists**. Works in Markdown, but not here in a .lua file. Seems like an easy fix.

-- TODO Move this into a scripts.lua file
-- local M = {}
--
-- function M.find_files()
--     local fzf = require('fzf-lua')
-- end

-- Neovim Highlight Groups
--------------------------------------------------------------------------------

-- Todo 
vim.cmd [[ highlight Todo guifg=#FF9E3B guibg=bg gui=bold ctermfg=178 cterm=bold ]]

-- Window Separator Highlights
vim.api.nvim_set_hl(0, 'WinSeparator', {foreground = 'bg'})

-- Plugin Highlight Groups
--------------------------------------------------------------------------------

-- Nvim Tree Highlights

vim.api.nvim_set_hl(0, 'NvimTreeWinSeparator', {foreground = 'bg'})

-- Removes the inactive status line colour behind the status line.
-- This is a bit of a hack. Without it there's a bit of a padding issue, the
-- same that occurs with the window separator.
vim.api.nvim_set_hl(0, 'NvimTreeStatusLineNC', {foreground = 'bg'})

-- Indent Blankline Highlights
-- —————————————————————————————————————

vim.api.nvim_set_hl(0, 'IndentBlanklineChar', {foreground = '#252535'})

-- Quick Scope Highlights
-- —————————————————————————————————————

-- TODO Convert these to lua api calls without losing cterm colours etc.
vim.cmd [[ highlight QuickScopePrimary guifg='#c82491' gui=bold cterm=bold ]]
vim.cmd [[ highlight QuickScopeSecondary guifg='#afff00']]

