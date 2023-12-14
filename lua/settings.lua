-- settings.lua
-- -------------------------------------------------------------------------- --

-- Helpers: `:h quickref.txt`
-- Defaults: https://neovim.io/doc/user/vim_diff.html

if vim.g.vscode then
    return
end

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

-- Environment

vim.o.hidden = true -- Retain undo information when a buffer is unloaded.
vim.o.filetype = 'on' -- Disables filetype detection. NOTE: Handled by filetype. Can I disable this?
vim.o.backup = false -- (Don't) make a backup before overwriting a file, and leave it around afterwards.
vim.o.writebackup = true -- Make a backup before overwriting a file, but delete it afterwards.
vim.api.nvim_set_option('undofile', true)
vim.api.nvim_set_option('mouse', 'a') -- Enables mouse scrolling in 'a'll modes.

-- Line-wrap

vim.o.linebreak = true -- Wrap text on word boundaries.
vim.o.wrap = false -- Wrap lines. 

-- Syntax

vim.wo.conceallevel = 0 -- Determines how text with the 'conceal' syntax attribute is shown. Was experimenting with hiding curly braces in .odin files.
vim.o.syntax = 'on' -- Enable syntax highlighting.
vim.o.list = false
-- vim.opt.listchars = { trail = '⋅'} -- Show trailing whitespace as a dot.

-- Colours

vim.o.termguicolors = true -- Enable true 24bit colour support; use 'gui' instead of 'cterm' in highlights.
vim.o.background = 'dark'

-- Status Line

vim.o.laststatus = 2 -- This needs to be called before 'fillchars'. 2: ensures that all windows have a status line. 3: enables the global status line.
vim.o.showcmd = false -- Show input in the status line.
vim.o.showmode = false -- Don't show the command line mode (e.g. '-- INSERT --') below the status line. (I implement my own mode presentation logic in `scripts.lua`.)

-- Line/Column

vim.o.cursorline = false -- Highlight the current line. Known to cause performance issues.
vim.o.number = false -- Hide line numbers.
vim.o.relativenumber = false
vim.o.fillchars = 'eob: ' -- This needs to be called after 'laststatus'. Remove empty buffer symbols.
vim.o.signcolumn = 'no' -- Force the signcolumn to remain hidden.

-- Search

vim.o.synmaxcol = 5000 -- Max columns to search for syntax items; 0 = infinity.
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
vim.o.smartindent = true -- Auto                          -inserts indents after a line: ending in '{', starting with a keyword from 'cinwords', other.
vim.o.breakindent = true -- Visually indent wrapped lines.
-- vim.o.showbreak = '␤ ' -- TODO: String at the start of wrapped lines.
-- vim.o.breakindentopt = 'shift:-2' -- TODO: Shift the wrapped line's beginning by 'n' spaces after applying 'breakindent'.

-- Timing

vim.g.redrawtime = 1 -- Time in ms to redraw the screen. (Default: 2000)
vim.o.updatetime = 4000 -- Write swap-file to disk every `updatetime` ms.
vim.o.timeoutlen = 500 -- Time in ms to wait for mapped sequences to complete.
vim.o.ttimeoutlen = 0 -- Time in ms to wait for for key-code sequences to complete.

-- Folds

vim.o.foldmethod = 'syntax' -- Line folds are specified by syntax highlighting.
-- vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
vim.o.foldlevel = 99 -- Zero closes all folds. Lower numbers close more folds, higher numbers open more folds. Keeping this at 99 to ensure folds don't appear.
-- vim.w.foldcolumn = 1 -- How many columns to use when drawing a fold.

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

-- Diagnostics

vim.diagnostic.config({ underline = false })

-- Vim Commands

-- vim.cmd [[ set ttyfast ]]
vim.cmd [[ autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o ]] -- Disable auto comment formatting. (`c`: auto-wrap comments; `r`: auto-insert comment leader after hitting <Enter> in Insert mode; `o`: Auto-insert the comment leader after hitting 'o' or 'O' in Normal mode.
-- vim.cmd [[ au BufNewFile,BufRead *.odin map=<C-P> :w<Return>:%!odinfmt %<Return> ]]
-- vim.cmd [[ au BufNewFile,BufRead *.odin set syntax=odin ]] -- Set Odin syntax highlighting for .odin files.
-- vim.cmd [[ au BufNewFile,BufRead *.odin set filetype=odin ]] -- Set Odin filetype for .odin files.
-- vim.cmd [[ au BufNewFile,BufRead *.go set syntax=go ]]
-- vim.cmd [[ au BufNewFile,BufRead *.go set filetype=go ]]
-- vim.cmd [[ let g:dracula_underline = 0 ]] -- Disable underlines in Dracula theme.
