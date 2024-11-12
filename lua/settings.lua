-- settings.lua
-- -------------------------------------------------------------------------- --

-- Helpers: `:h quickref.txt`
-- Defaults: https://neovim.io/doc/user/vim_diff.html

-- -------------------------------------------------------------------------- --

-- VSCode
-- -------------------------------------------------------------------------- --

if vim.g.vscode then
    return
end

-- Neovide
-- -------------------------------------------------------------------------- --
-- https://neovide.dev/configuration.html

if vim.g.neovide then
    vim.o.guifont = "PragmataPro:h14"
    vim.o.linespace = 1
    vim.g.neovide_cursor_animation_length = 0.05
    vim.g.neovide_cursor_trail_size = 0.10
    vim.g.neovide_scroll_animation_length = 0.1
    vim.g.neovide_underline_stroke_scale = 1.0
    vim.g.neovide_cursor_antialiasing = true
    vim.g.neovide_padding_top = 22
    vim.g.neovide_padding_bottom = 22
    vim.g.neovide_padding_right = 22
    vim.g.neovide_padding_left = 22
    vim.g.neovide_show_border = false
    vim.g.neovide_remember_previous_window_size = true
    vim.g.neovide_refresh_rate = 144
    vim.g.neovide_refresh_rate_idle = 30
    vim.g.neovide_scale_factor = 1.00
end

-- Neovim
-- -------------------------------------------------------------------------- --

-- Standard Plugins

-- Note: Tell Vim's 'standard plugins' to finish early. In other words, tell Vim
-- that the following standard plugins have already been loaded even though they
-- haven't. This doesn't seem very reliable though, as the plugins still eat
-- into `startuptime` when `rtp plugins` are sourced.

-- See: `:h standard-plugin`, `:h standard-plugin-list` and `:h load-plugins`.

vim.g.loaded_netrw = 1 -- Disable the 'netrw' plugin.
vim.g.loaded_netrwPlugin = 1 -- Disable the 'netrw' plugin.
vim.g.loaded_zip = 1 -- Disables 'zip' plugin.
vim.g.loaded_zipPlugin = 1 -- Disables 'zip' plugin.
vim.g.loaded_gzip = 1 -- Disables 'gzip' plugin.
vim.g.loaded_tutor = 1 -- Disable the 'tutor' plugin.
vim.g.loaded_tarPlugin = 1 -- Disables 'tar' plugin.
vim.g.loaded_tar = 1 -- Disables 'tar' plugin.

-- Core Environment

vim.o.hidden = true -- Retain undo information when a buffer is unloaded.
vim.o.backup = false -- (Don't) make a backup before overwriting a file, and leave it around afterwards.
vim.o.writebackup = true -- Make a backup before overwriting a file, but delete it afterwards.
vim.o.undofile = true -- Save undo history to a file.
vim.o.mouse = 'a' -- Enable all mouse modes.
vim.o.timeoutlen = 300 -- Mapping timeout.
vim.o.ttimeoutlen = 0 -- Key code timeout.
vim.o.updatetime = 4000 -- Swap file write frequency. (Default: 4000)
vim.g.redrawtime = 16 -- Time in ms to redraw the screen. (Default: 2000)
vim.o.filetype = 'on' -- Disables filetype detection. NOTE: Handled by filetype. Can I disable this?

-- Text Formatting

vim.o.linebreak = true -- Wrap text on word boundaries.
vim.o.wrap = true -- Wrap lines. 
vim.o.breakindent = true -- Visually indent wrapped lines.

-- Syntax

vim.o.syntax = 'on' -- Enable syntax highlighting.
vim.wo.conceallevel = 0 -- Determines how text with the 'conceal' syntax attribute is shown. Was experimenting with hiding curly braces in .odin files.
vim.o.list = false
vim.o.spelllang = 'en_gb' -- Set the spell-checking language.
vim.o.spell = true
vim.opt.listchars = { trail = '⋅'} -- Show trailing whitespace as a middle-dot.

-- Line/Column

vim.o.cursorline = true -- Highlight the current line. Known to cause performance issues.
vim.o.rnu = true
vim.o.numberwidth = 2
-- vim.opt.statuscolumn = "%=%#DimmedZeros#%{v:virtnum < 1 ? repeat('0', strlen(line('$')) - strlen(abs(v:relnum > 0 ? v:relnum : v:lnum))) : ''}%#LineNr#%{v:virtnum < 1 ? (v:relnum ? abs(v:relnum) : v:lnum) : ''} %*%=%s"
-- vim.opt.statuscolumn = "%!v:lua.format_line_number()"
vim.o.relativenumber = false
vim.o.fillchars = 'eob: ' -- This needs to be called after 'laststatus'. Remove empty buffer symbols.
vim.o.signcolumn = 'no' -- Force the signcolumn to remain hidden.

-- Colours

vim.o.termguicolors = true -- Enable true 24bit colour support; use 'gui' instead of 'cterm' in highlights.
vim.o.background = 'dark'

-- Status Line

vim.o.laststatus = 2 -- This needs to be called before 'fillchars'. 2: ensures that all windows have a status line. 3: enables the global status line.
vim.o.showcmd = false -- Show input in the status line.
vim.o.showmode = false -- Don't show the command line mode (e.g. '-- INSERT --') below the status line. (I implement my own mode presentation logic in `scripts.lua`.)

-- Search

vim.o.synmaxcol = 0 -- Max columns to search for syntax items; 0 = infinity.
vim.o.incsearch = true -- Show search results as you type.
vim.o.hlsearch = true -- Highlight search results.
vim.o.showmatch  = true -- Highlight matching braces, etc.
vim.o.ignorecase = true -- Ignore case when searching in lowercase (case insensitive search)...
vim.o.smartcase = true -- Unless there's a capital letter in the query (case sensitive search).
vim.o.inccommand = 'nosplit' -- Shows the results of a command (like ':%s') in the buffer.

-- Indentation

vim.o.shiftwidth = 4 -- Number spaces to use for each step of 'autoindent'; used for 'cindent', >>, <<, etc.
vim.o.tabstop = 4 -- Number of spaces that a <Tab> in the file counts for.
vim.o.expandtab = true -- In Insert mode, use the appropriate number of spaces when inserting a <Tab>.
vim.o.autoindent = true -- Copy indent from current line when starting a new line.
vim.o.smartindent = true
-- vim.o.showbreak = '␤ ' -- TODO: String at the start of wrapped lines.
-- vim.o.breakindentopt = 'shift:-2' -- TODO: Shift the wrapped line's beginning by 'n' spaces after applying 'breakindent'.

-- Timing


-- Folds

vim.o.foldmethod = 'syntax' -- Line folds are specified by syntax highlighting.
-- vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
vim.o.foldlevel = 99 -- Zero closes all folds. Lower numbers close more folds, higher numbers open more folds. Keeping this at 99 to ensure folds don't appear.
-- vim.w.foldcolumn = 1 -- How many columns to use when drawing a fold.

-- Buffers

vim.o.splitright = true -- Split new windows to the right.

-- Autocmds

-- Highlight yanked text on yank
-- https://www.reddit.com/r/neovim/comments/ypvrwp/comment/ivnl294/
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('yank_highlight', {}),
    pattern = '*',
    callback = function ()
        vim.highlight.on_yank { higroup = 'IncSearch', timeout = 600 }
    end,
})

-- LSP and Diagnostics

vim.diagnostic.config({ underline = false })
vim.lsp.set_log_level("ERROR") -- Reduced logging verbosity by setting the log level to 'ERROR'.
vim.lsp.handlers["workspace/didChangeWatchedFiles"] = { dynamic_registration = true }

-- Vim Commands

-- vim.cmd [[ set ttyfast ]]
vim.cmd [[ autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o ]] -- Disable auto-comments
vim.cmd [[ autocmd BufWinEnter,WinEnter term://* startinsert ]]
vim.cmd [[ autocmd BufLeave term://* stopinsert]]

-- ARCHIVE

-- This activates cowboy mode, which complains when you spam movement keys.
-- local discipline = require("scripts")
-- discipline.cowboy()

-- Open files in tabs
-- vim.api.nvim_create_autocmd("BufNewFile,BufRead", {
--     pattern = "*",
--     callback = function()
--         if #vim.api.nvim_list_wins() >= 1 then
--             vim.cmd("tabnew")
--         end
--     end,
-- })

-- vim.cmd [[ au BufNewFile,BufRead *.odin map=<C-P> :w<Return>:%!odinfmt %<Return> ]]
-- vim.cmd [[ au BufNewFile,BufRead *.odin set syntax=odin ]] -- Set Odin syntax highlighting for .odin files.
-- vim.cmd [[ au BufNewFile,BufRead *.odin set filetype=odin ]] -- Set Odin filetype for .odin files. (Handled by filetype plugin.)
-- vim.cmd [[ au BufNewFile,BufRead *.go set syntax=go ]]
-- vim.cmd [[ au BufNewFile,BufRead *.go set filetype=go ]]
-- vim.cmd [[ let g:dracula_underline = 0 ]] -- Disable underlines in Dracula theme.
