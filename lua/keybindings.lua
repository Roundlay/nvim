-- keybindings.lua

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

if vim.g.vscode then

    vim.g.mapleader = ' '
    vim.g.maplocalleader = ' '

    normal('<n>', '<C-v>', "WIN: Fixes paste overlap w/ Visual Command Mode.")

    normal('<leader>y', '"+y', "Yank to system clipboard.")
    normal('<leader>yy', '"+yy', "Yank current line to the system clipboard.")
    normal('<leader>Y', '"+Y', "Yank to end of line to the system clipboard.")
    visual('<leader>y', '"+y', "Yank the selection to the system clipboard.")

    normal('<leader>p', '"+p', "Put from system clipboard after the cursor.")
    normal('<leader>P', '"+P', "Put from system clipboard before the cursor.")
    visual('<leader>p', '"+p', "Put from system clipboard in visual mode.")
    visual('<leader>P', '"+P', "Put from system clipboard before the visual selection.")

    normal('J', '}', "Jump one paragraph backwards.")
    normal('K', '{', "Jump one paragraph forwards.")
    visual('J', '}', "Jump one paragraph backwards in visual mode.")
    visual('K', '{', "Jump one paragraph forwards in visual mode.")

    visual('p', 'pgvy', "Put then re-yank the original selection.")

    -- Use VSCode's comment line command instead of vim's native commands
    normal("gcc", "<cmd>lua require('vscode').action('editor.action.commentLine')<CR>", "Toggle line comment with VSCode.")
    normal("gc", "<cmd>lua require('vscode').action('editor.action.commentLine')<CR>", "Toggle line comment with VSCode.")
    visual("gc", "<cmd>lua require('vscode').action('editor.action.commentLine')<CR>", "Toggle line comment for selection with VSCode.")

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

-- KEYBINDINGS

-- Leaders

-- These are defined in init.lua as per Lazy's documentation.

-- vim.g.mapleader = ' '
-- vim.g.maplocalleader = ' '

-- Movement

normal('J', '}', "Jump one paragraph backwards.")
normal('K', '{', "Jump one paragraph forwards.")
visual('J', '}', "Jump one paragraph backwards in visual mode.")
visual('K', '{', "Jump one paragraph forwards in visual mode.")

normal('<C-Up>', 'ddkP', "Move the current line up.")
normal('<C-Down>', 'ddp', "Move the current line down.")
visual('<C-Down>', 'xp`[V`]', "Move selection down.")
visual('<C-Up>', 'xkP`[V`]', "Move selection up.")

-- TODO: Reset the replace keybinding which is C-e to the default behaviour so that you don't need to redefine scroll down.
normal('<C-i>', '<C-e>', "Scroll window down one line.")

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

-- Window/Tab/Buffer management

-- Buffer Management

normal('<leader>b', ':w<CR>:bd<CR>', "Save and close the current buffer.")

-- Tab Management

normal('<leader>tn', ':tabnew<CR>',    "Open a new tab")
normal('<leader>tb', ':tab split<CR>', "Open current buffer in new tab")
normal('<leader>tq', ':tabclose<CR>', "Close the current tab")
normal('<leader>tx', ':tabonly<CR>', "Close all tabs except the current one")
normal('<leader>tl', ':tabnext<CR>', "Go to next tab")
normal('<leader>th', ':tabprevious<CR>', "Go to previous tab")
normal('<C-Right>', ':tabnext<CR>', "Go to next tab")
normal('<C-Left>', ':tabprevious<CR>', "Go to previous tab")
normal('<A-Right>', ':tabmove +1<CR>', "Move tab to the right")
normal('<A-Left>', ':tabmove -1<CR>', "Move tab to the left")

-- This moves the line the cursor is on up one line.
normal('<A-k>', ':m .-2<CR>==', "Move the current cursor-line up one line.")
normal('<A-j>', ':m .+1<CR>==', "Move the current cursor-line down one line.")

-- TERMINAL MANAGEMENT AND MOVEMENT

-- TODO [ ] Can we detect when we're in a terminal buffer?
-- I.e. can we preface window movements with ESC so that we can move around freely.
normal('<leader>tt', ':vs | terminal<CR>', "Open a terminal in a vertical split")
terminal('<Esc>', '<C-\\><C-n>', "Exit terminal mode")
terminal('<C-w>', '<C-\\><C-n>', "Exit insert mode and wait for window command")
terminal('<C-w>h', '<C-\\><C-n><C-w>h', "Move to the left window from terminal insert mode")
terminal('<C-w>l', '<C-\\><C-n><C-w>l', "Move to the right window from terminal insert mode")
terminal('<C-w>k', '<C-\\><C-n><C-w>k', "Move to the window above from terminal insert mode")
terminal('<C-w>j', '<C-\\><C-n><C-w>j', "Move to the window below from terminal insert mode")

-- PLUGINS

-- Oil

normal('<leader>o', ':Oil<CR>', "Open the Oil file explorer.")
normal('<leader>e', '</<C-X><C-O>', "Unknown mapping related to Oil and terminal.") -- TODO: Was this something to do with Oil interacting with the terminal?

-- Visual Replace

visual('<leader>r', '<Esc>:lua Visrep()<CR>', "Search for all instances then replace the visually selected text with a new string.")

-- Tag Wrapper

normal('<leader>w', ':lua WrapWithTags()<CR>', "Wrap current line with tags on separate lines.")
visual('<leader>w', '<Esc>:lua WrapWithTags()<CR>', "Wrap selection with tags on separate lines.")

-- Misc

normal('<n>', '<C-v>', "WIN: Fixes paste overlap within Visual Command Mode.")
normal('<leader>l', ':Lazy<CR>', "Open the Lazy plugin manager.")
normal("<leader>dt", ":lua vim.api.nvim_put({os.date('%Y-%m-%d ')}, 'c', true, true)<CR>", "Insert current date at cursor.")
normal("<leader>dtt", ":lua vim.api.nvim_put({os.date('%Y-%m-%d %H:%M:%S')}, 'c', true, true)<CR>", "Insert current date and time at cursor.")
normal('<leader>s', ':lua vim.cmd("source " .. vim.fn.expand("%:p")) print(vim.fn.expand("%:p") .. " sourced.")<CR>', "Source the current file.")

local function call_script(fn_name)
    return function(...)
        local ok = pcall(require, "scripts")
        if not ok then
            return
        end
        local fn = _G[fn_name]
        if type(fn) == "function" then
            return fn(...)
        end
    end
end

vim.keymap.set('n', '<leader>tr', call_script("trim"), { desc = "Trim whitespace from the current line.", silent = true })

-- ARCHIVE

-- Wrappin' Tests

vim.keymap.set('v', '<F2>', call_script("Wrappin"), { desc = "Wrap selection with tags on separate lines.", silent = true })
vim.keymap.set('v', '<F3>', call_script("WrappinTest"), { desc = "Test Wrappin transformation.", silent = true })
vim.keymap.set('n', '<F5>', call_script("ReloadScripts"), { desc = "Reload scripts in scripts.lua.", silent = true })
vim.keymap.set('n', '<F6>', call_script("Slect"), { desc = "Run the experimental Slect workflow.", silent = true })
vim.keymap.set('v', '<F6>', call_script("Slect"), { desc = "Run the experimental Slect workflow on selection.", silent = true })

-- Copilot

local function with_copilot(method)
    return function(...)
        local lazy_ok, lazy = pcall(require, "lazy")
        if lazy_ok then
            lazy.load({ plugins = { "copilot.lua" }, wait = true })
        end
        local ok, suggestion = pcall(require, "copilot.suggestion")
        if not ok then
            return
        end
        local fn = suggestion[method]
        if type(fn) ~= "function" then
            return
        end
        return fn(...)
    end
end

-- Keybinding to enable/disable Copilot
vim.keymap.set('n', '<leader>co', with_copilot("toggle_auto_trigger"), { desc = "Toggle Copilot suggestion visibility" })

-- Keep C-\ as backup
vim.keymap.set('i', '<C-CR>', with_copilot("accept"), { desc = "Accept Copilot suggestion (backup)" })

-- Blink

-- TODO: Blink seems to have a unique way of handling keybindings that doesn't work with the standard vim.keymap.set function?
-- TODO: See /lua/plugins/lazy-blink-cmp.lua for more details.
-- vim.keymap.set('n', '<C-\\>', require('blink.cmp').select_and_accept, {desc = "Select and accept the current Blink suggestion"})
-- vim.keymap.set('n', '<C-CR>', require('blink.cmp').select_and_accept, {desc = "Select and accept the current Blink suggestion (backup)"})
-- vim.keymap.set('n', '<C-p>', require('blink.cmp').select_prev, {desc = "Select the previous Blink suggestion"})
-- vim.keymap.set('n', '<C-n>', require('blink.cmp').select_next, {desc = "Select the next Blink suggestion"})
