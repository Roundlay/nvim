-- {Keybindings}
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

local function normal(new, old)
    vim.api.nvim_set_keymap('n', new, old, {noremap=true, silent=true})
end

local function visual(new, old)
    vim.api.nvim_set_keymap('v', new, old, {noremap=true, silent=true})
end

local function insert(new, old)
    vim.api.nvim_set_keymap('i', new, old, {noremap=true, silent=true})
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
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Required by lazy.nvim and therefore this file needs to be called before lazy
-- is loaded in init.lua.

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Misc.
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

normal('<n>', '<C-v>') -- ? WIN: Fixes paste overlap within Visual Command Mode.

-- Save & Close Buffer (without closing Neovim)

normal('<leader>b', ':w<CR>:bd<CR>')

-- Alternate Escape
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

normal('<C-j>', '<esc>')
visual('<C-j>', '<esc>')
insert('<C-j>', '<esc>')

-- Jump Navigation
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Jump up and down by paragraph in Normal/Visual mode.

normal('J', '}')
normal('K', '{')
visual('J', '}')
visual('K', '{')

-- Jump to the beginning and end of the active line in Normal/Visual mode.
-- NOTE: Disabled for now, because I just never ended up using these, and I'd
-- prefer to have access to <H>igh and <L>ow.

-- normal('L', '$')
-- normal('H', '_')
-- visual('L', '$')
-- visual('H', '_')

-- Yank & Put
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Put then re-yank original selection.

visual('p', 'pgvy')

-- Yank to system clipboard.

normal('<leader>y', '"+y')
normal('<leader>yy', '"+yy')
normal('<leader>Y', '"+Y')
visual('<leader>y', '"+y')

-- Put from system clipboard.

normal('<leader>p', '"+p')
normal('<leader>P', '"+P')
visual('<leader>p', '"+p')
visual('<leader>P', '"+P')

-- Bubble Selection
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- NOTE [ ] These don't seem to work with remapped arrow keys on HHKBs.
-- TODO [ ] These trigger the auto-save plugin every time they're used.

normal('<C-Up>', 'ddkP')
normal('<C-Down>', 'ddp')
visual('<C-Down>', 'xp`[V`]')
visual('<C-Up>', 'xkP`[V`]')

--------------------------------------------------------------------------------
-- Lazy
--------------------------------------------------------------------------------

-- Toggle Lazy

normal('<leader>l', ':Lazy<CR>')

--------------------------------------------------------------------------------
-- Wrappin
--------------------------------------------------------------------------------

-- TODO [ ] Turn this into a plugin.

-- Test lines:

-- You can use the system message to describe the assistant’s personality, 
-- define what the model should and shouldn’t answer, and define the format of 
-- model responses. And this is me testing just so I know. 

visual('<F2>', ':lua _G.Wrappin()<CR>')
visual('<F3>', ':lua _G.WrappinTest()<CR>')
normal('<F5>', ':lua _G.ReloadScripts()<CR>') -- Reload scripts in scripts.lua.
normal('<F6>', ':lua _G.Slect()<CR>')
visual('<F6>', ':lua _G.Slect()<CR>')
