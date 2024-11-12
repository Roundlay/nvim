-- {Keybindings}

-- Helpers

local function normal(new, old, description)
    vim.api.nvim_set_keymap('n', new, old, {noremap=true, silent=true, desc=description})
end

local function visual(new, old, description)
    vim.api.nvim_set_keymap('v', new, old, {noremap=true, silent=true, desc=description})
end

local function insert(new, old, description)
    vim.api.nvim_set_keymap('i', new, old, {noremap=true, silent=true, desc=description})
end

local function terminal(new, old, description)
    vim.api.nvim_set_keymap('t', new, old, {noremap=true, silent=true, desc=description})
end

-- VSCode

if (vim.g.vscode) then
    normal('<n>', '<C-v>', "WIN: Fixes paste overlap w/ Visual Command Mode.")

    -- normal('J', '}', "Jump n paragraphs backwards.")
    -- normal('K', '{', "Jump n paragraphs forwards.")
    -- normal('L', '$', "Jump to the end of the active line.")
    -- normal('H', '_', "Jump to the beginning of the active line.")

    -- visual('J', '}', "Jump n paragraphs backwards in visual mode.")
    -- visual('K', '{', "Jump n paragraphs forwards in visual mode.")
    -- visual('L', '$', "Jump to the end of the active line in Visual mode.")
    -- visual('H', '_', "Jump to the beginning of the active line in Visual mode.")

    normal('<leader>y', '"+y', "Yank to system clipboard.")
    normal('<leader>yy', '"+yy', "Yank current line to the system clipboard.")
    normal('<leader>Y', '"+Y', "Yank to end of line to the system clipboard.")
    visual('<leader>y', '"+y', "Yank the selection to the system clipboard.")

    normal('<leader>p', '"+p', "Put from system clipboard after the cursor.")
    normal('<leader>P', '"+P', "Put from system clipboard before the cursor.")
    visual('<leader>p', '"+p', "Put from system clipboard in visual mode.")
    visual('<leader>P', '"+P', "Put from system clipboard before the visual selection.")

    return
end

-- Neovide
-- https://github.com/neovide/neovide/issues/1301#issuecomment-1705046950 

if vim.g.neovide then
    vim.api.nvim_set_keymap("n", "<C-=>", ":lua vim.g.neovide_scale_factor = math.min(vim.g.neovide_scale_factor + 0.1,  1.0)<CR>", { silent = true, desc = "Increase Neovide scale factor." })
    vim.api.nvim_set_keymap("n", "<C-->", ":lua vim.g.neovide_scale_factor = math.max(vim.g.neovide_scale_factor - 0.1,  0.1)<CR>", { silent = true, desc = "Decrease Neovide scale factor." })
    vim.api.nvim_set_keymap("n", "<C-+>", ":lua vim.g.neovide_transparency = math.min(vim.g.neovide_transparency + 0.05, 1.0)<CR>", { silent = true, desc = "Increase Neovide transparency." })
    vim.api.nvim_set_keymap("n", "<C-_>", ":lua vim.g.neovide_transparency = math.max(vim.g.neovide_transparency - 0.05, 0.0)<CR>", { silent = true, desc = "Decrease Neovide transparency." })
    vim.api.nvim_set_keymap("n", "<C-0>", ":lua vim.g.neovide_scale_factor = 0.5<CR>", { silent = true, desc = "Set Neovide scale factor to 0.5." })
    vim.api.nvim_set_keymap("n", "<C-)>", ":lua vim.g.neovide_transparency = 0.9<CR>", { silent = true, desc = "Set Neovide transparency to 0.9." })
end

-- This activates cowboy mode, which complains when you spam movement keys.
-- local discipline = require("scripts")
-- discipline.cowboy()

-- Keybindings

-- Required by lazy.nvim and therefore this file needs to be called before lazy
-- is loaded in init.lua.

-- Leaders

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Movement

normal('<C-j>', '<esc>', "Map <C-j> to <esc> in normal mode.")
visual('<C-j>', '<esc>', "Map <C-j> to <esc> in visual mode.")
insert('<C-j>', '<esc>', "Map <C-j> to <esc> in insert mode.")

normal('J', '}', "Jump one paragraph backwards.")
normal('K', '{', "Jump one paragraph forwards.")
visual('J', '}', "Jump one paragraph backwards in visual mode.")
visual('K', '{', "Jump one paragraph forwards in visual mode.")

-- normal('<C-Up>', 'ddkP', "Move the current line up.")
-- normal('<C-Down>', 'ddp', "Move the current line down.")
-- visual('<C-Down>', 'xp`[V`]', "Move selection down.")
-- visual('<C-Up>', 'xkP`[V`]', "Move selection up.")

-- Yank and put

normal('<leader>y', '"+y', "Yank to system clipboard.")
normal('<leader>yy', '"+yy', "Yank current line to the system clipboard.")
normal('<leader>Y', '"+Y', "Yank to end of line to the system clipboard.")
visual('<leader>y', '"+y', "Yank the selection to the system clipboard.")

normal('<leader>p', '"+p', "Put from system clipboard after the cursor.")
normal('<leader>P', '"+P', "Put from system clipboard before the cursor.")
visual('<leader>p', '"+p', "Put from system clipboard in visual mode.")
visual('<leader>P', '"+P', "Put from system clipboard before the visual selection.")

visual('p', 'pgvy', "Put then re-yank the original selection.")

-- Window/tab/buffer management

normal('<leader>b', ':w<CR>:bd<CR>', "Save and close the current buffer.")

-- This moves the line the cursor is on up one line.
normal('<A-k>', ':m .-2<CR>==', "Move the current cursor-line up one line.")
normal('<A-j>', ':m .+1<CR>==', "Move the current cursor-line down one line.")

-- TERMINAL MANAGEMENT AND MOVEMENT

-- TODO [ ] Can we detect when we're in a terminal buffer?
-- I.e. can we preface window movements with ESC so that we can move around freely.
normal('<leader>t', ':vs | terminal<CR>', "Open a terminal in a vertical split.")
terminal('<Esc>', '<C-\\><C-n>', "Exit terminal mode.")
terminal('<C-w>h', '<C-\\><C-n><C-w>h', "Move to the left window from the terminal.")
terminal('<C-w>l', '<C-\\><C-n><C-w>l', "Move to the right window from the terminal.")
terminal('<C-w>k', '<C-\\><C-n><C-w>k', "Move to the window above from the terminal.")
terminal('<C-w>j', '<C-\\><C-n><C-w>j', "Move to the window below from the terminal.")

-- Comment

normal("gcc", "gcc", "Toggle line comment.")
normal("gc", "gc", "Toggle block comment.")

-- Oil

normal('<leader>o', ':Oil<CR>', "Open the Oil file explorer.")
-- TODO: Was this something to do with Oil interacting with the terminal?
normal('<leader>e', '</<C-X><C-O>', "Unknown mapping related to Oil and terminal.")

-- Visual Replace

visual('<leader>r', '<Esc>:lua Visrep()<CR>', "Search for all instances then replace the visually selected text with a new string.")

-- Misc

normal('<n>', '<C-v>', "WIN: Fixes paste overlap within Visual Command Mode.")
normal('<leader>l', ':Lazy<CR>', "Open the Lazy plugin manager.")
normal("<leader>dt", ":lua vim.api.nvim_put({os.date('%Y-%m-%d ')}, 'c', true, true)<CR>", "Insert current date at cursor.")
normal("<leader>dtt", ":lua vim.api.nvim_put({os.date('%Y-%m-%d %H:%M:%S')}, 'c', true, true)<CR>", "Insert current date and time at cursor.")
normal('<leader>s', ':lua vim.cmd("source " .. vim.fn.expand("%:p")) print(vim.fn.expand("%:p") .. " sourced.")<CR>', "Source the current file.")

-- ARCHIVE

-- Wrappin' Tests

-- visual('<F2>', ':lua _G.Wrappin()<CR>')
-- visual('<F3>', ':lua _G.WrappinTest()<CR>')
-- normal('<F5>', ':lua _G.ReloadScripts()<CR>') -- Reload scripts in scripts.lua.
-- normal('<F6>', ':lua _G.Slect()<CR>')
-- visual('<F6>', ':lua _G.Slect()<CR>')

-- Yanky

-- normal("y", "<Plug>(YankyYank)")
-- normal("p", "<Plug>(YankyPutAfter)")
-- normal("P", "<Plug>(YankyPutBefore)")
-- normal("gp", "<Plug>(YankyGPutAfter)")
-- normal("gP", "<Plug>(YankyGPutBefore)")
-- normal("<C-p>", "<Plug>(YankyPreviousEntry)")
-- normal("<C-n>", "<Plug>(YankyNextEntry)")

-- Text to Colorscheme

-- vim.api.nvim_set_keymap('n', '<f9>', ':T2CAddContrast -0.1<cr>', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', '<f10>', ':T2CAddContrast 0.1<cr>', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', '<f11>', ':T2CAddSaturation -0.1<cr>', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', '<f12>', ':T2CAddSaturation 0.1<cr>', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', '<f8>', ':T2CShuffleAccents<cr>', {noremap = true, silent = true})
