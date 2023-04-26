-- keybindings.lua
--------------------------------------------------------------------------------

-- Helper Functions
-- -------------------------------------------------------------------------- --

local function normal(new, old)
    vim.api.nvim_set_keymap('n', new, old, {noremap=true, silent=true})
end

local function visual(new, old)
    vim.api.nvim_set_keymap('v', new, old, {noremap=true, silent=true})
end

--------------------------------------------------------------------------------
-- VS Code
--------------------------------------------------------------------------------

if (vim.g.vscode) then
    normal('J', '}') -- Jump n paragraphs backwards.
    normal('K', '{') -- Jump n paragraphs forwards.
    normal('L', '$') -- Jump to the end of the active line.
    normal('H', '_') -- Jump to the beginning of the active line.
    visual('J', '}') -- Jump n paragraphs backwards in visual mode.
    visual('K', '{') -- Jump n paragraphs forwards in visual mode.
    visual('L', '$') -- Jump to the end of the active line in Visual mode.
    visual('H', '_') -- Jump to the beginning of the active line in Visual mode.
    -- normal('<n>', '<C-v>') -- WIN: Fixes paste overlap w/ Visual Command Mode.
    return
end

--------------------------------------------------------------------------------
-- Neovim
--------------------------------------------------------------------------------

-- Leader
-- -------------------------------------------------------------------------- --

-- Required by lazy.nvim and therefore this file needs to be called before lazy
-- is loaded in init.lua.

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Misc.
--------------------------------------------------------------------------------

normal('<n>', '<C-v>') -- WIN: Fixes paste overlap within Visual Command Mode.

-- Escape
-- -------------------------------------------------------------------------- --

-- normal('<C-j>', '<esc>l')
-- visual('<C-j>', '<esc>l')
-- insert('<C-j>', '<esc>l')
-- normal('<leader-o>', 'o<Esc>^D0') -- Huh?

-- Navigation
-- -------------------------------------------------------------------------- --

-- Jump up and down by paragraph in Normal mode.

normal('J', '}')
normal('K', '{')

-- Jump to the beginning and end of the active line in Normal mode.

normal('L', '$')
normal('H', '_')

-- Jump up and down by paragraph in Normal mode.

visual('J', '}')
visual('K', '{')

-- Jump to the beginning and end of the active line in Visual mode.

visual('L', '$')
visual('H', '_')


-- Yank & Put
-- -------------------------------------------------------------------------- --

-- Put and re-yank original selection.

visual('p', 'pgvy')

-- Yank to System Clipboard.

normal('<leader>y', '"+y')
normal('<leader>yy', '"+yy')
normal('<leader>Y', '"+Y')
visual('<leader>y', '"+y')

-- Put from System Clipboard.

normal('<leader>p', '"+p')
normal('<leader>P', '"+P')
visual('<leader>p', '"+p')
visual('<leader>P', '"+P')
