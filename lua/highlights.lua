-- TODO: Padding around windows needs to be configurable.
-- TODO: A line separator between windows would be nice, but currently it appears offset with the background colour of the active buffer. Find out why this is happening.
-- TODO: Highlighting for **task lists**. Works in Markdown, but not here in a .lua file. Seems like an easy fix.
-- TODO: Non-global statusline still has padding issues at break point.

-- Kanagawa Alacritty Colors
-- -------------------------------------------------------------------------- --

local background = '#1f1f28'
local foreground = '#dcd7ba'
local fujiwhite = '#DCD7BA'
local sumiink4 = '#54546D'
local waveblue2 = '#2D4F67'
local black = '#090618'
local red = '#c34043'
local green = '#76946a'
local yellow = '#c0a36e'
local blue = '#7e9cd8'
local magenta = '#957fb8'
local cyan = '#6a9589'
local white = '#c8c093'
local bright_black = '#727169'
local bright_red = '#e82424'
local bright_green = '#98bb6c'
local bright_yellow = '#e6c384'
local bright_blue = '#7fb4ca'
local bright_magenta = '#938aa9'
local bright_cyan = '#7aa89f'
local bright_white = '#dcd7ba'
local selection_background = '#2d4f67'
local selection_foreground = '#c8c093'

if vim.g.vscode then

    -- ---------------------------------------------------------------------- --
    -- Visual Studio Code Highlight Groups
    -- ---------------------------------------------------------------------- --

else

    -- ====================================================================== --
    -- Neovim Highlight Groups
    -- ====================================================================== --

    -- Todo Highlight Group 
    -- ---------------------------------------------------------------------- --

    vim.cmd [[ highlight Todo guifg=#FFFFFF guibg=bg gui=bold cterm=bold ]]

    -- Window Separator Highlights
    -- ---------------------------------------------------------------------- --

    -- vim.api.nvim_set_hl(0, 'WinSeparator', {foreground = 'bg'})

    -- ---------------------------------------------------------------------- --
    -- Plugin Highlight Groups
    -- ---------------------------------------------------------------------- --

    -- Nvim Tree Highlights
    -- ---------------------------------------------------------------------- --

    vim.api.nvim_set_hl(0, 'NvimTreeWinSeparator', {foreground = background})

    -- Removes the inactive status line colour behind the status line.
    -- This is a bit of a hack. Without it there's a bit of a padding issue, the
    -- same that occurs with the window separator.
    -- vim.api.nvim_set_hl(0, 'NvimTreeStatusLineNC', {foreground = 'bg'})

    -- Indent Blankline Highlights
    -- ---------------------------------------------------------------------- --

    -- TODO: Figure out a way to check which theme is currently active so that
    -- you can set the indent blankline colours to match the theme.

    -- Kanagawa Indent Blankline Highlight
    -- ---------------------------------------------------------------------- --

    vim.api.nvim_set_hl(0, 'IndentBlanklineChar', {foreground = '#252535'})

    -- Code Dark Indent Blankline Highlight
    -- ---------------------------------------------------------------------- --

    -- vim.api.nvim_set_hl(0, 'IndentBlanklineChar', {foreground = '#252535'})

    -- Quick Scope Highlights
    -- ---------------------------------------------------------------------- --

    -- TODO Convert these to lua api calls without losing cterm colours etc.
    vim.api.nvim_set_hl(0, 'QuickScopePrimary', {foreground = '#FF00FF', bold = true, blend = 100})
    vim.api.nvim_set_hl(0, 'QuickScopeSecondary', {foreground = '#00FF00', bold = false, blend = 50})

end

