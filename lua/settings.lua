-- ========================================================================== --
-- Neovim Settings
-- ========================================================================== --

-- Notes
-- -------------------------------------------------------------------------- --

-- https://github.com/mukeshsoni/config/blob/master/.config/nvim/init.lua
-- Echo Neovim's runtimepath variables.
-- print(vim.inspect(vim.api.nvim_list_runtime_paths()))
-- Primer on highlighting in Vimscript:
-- https://gist.github.com/romainl/379904f91fa40533175dfaec4c833f2f

if (vim.g.vscode) then

    -- ===================================================================== --
    -- Visual Studio Code Settings
    -- ===================================================================== --

    vim.cmd([[ let g:qs_highlight_on_keys = ['f', 'F'] ]])

    -- Colours based on: https://icolorpalette.com/color/pantone-16-0836-tcx
    vim.cmd([[
        highlight QuickScopePrimary guifg='#c8b273'
        highlight QuickScopeSecondary guifg='#73c7b2'
    ]])

else

    -- ====================================================================== --
    -- Neovim Settings
    -- ====================================================================== --

    -- ---------------------------------------------------------------------- --
    -- Global
    -- ---------------------------------------------------------------------- --

    -- Netrw
    -- ---------------------------------------------------------------------- --

    -- NOTE: :Lexplore opens a netrw window to the left of the current window.

    vim.g.loaded_netrw = 1 -- Set to 1 to disable netrw completely.
    vim.g.loaded_netrwPlugin = 1 -- Set to 1 to disable netrw plugins.
    vim.g.netrw_banner = 0 -- Remove the banner that appears when opening netrw.
    vim.g.netrw_liststyle = 3
    vim.g.netrw_browse_split = 4 -- 2: horizontal split, 2: vertical split, 3: tab, 4: previous window
    vim.g.netrw_altv = 1 -- ...
    vim.g.netrw_winsize = 20

    vim.g.redrawtime = 2000 -- Time in ms to redraw the screen. (Default: 2000)

    -- Misc
    -- ---------------------------------------------------------------------- --

    vim.o.encoding = 'utf-8'
    vim.o.background = 'dark'
    vim.o.hidden = true -- Retain undo information when a buffer is unloaded (incl. ToggleTerm)
    vim.o.termguicolors = true -- Enable true 24bit colour support; required for custom Neovim theme.

    -- Syntax
    -- --------------------------------------------------------------------- --

    vim.o.ignorecase = true -- Ignore case when searching.
    vim.o.smartcase = true -- Don't ignore case with capitals.
    vim.o.hlsearch = true -- Highlight search results.
    vim.o.synmaxcol = 0 -- Max columns (letters) to search for syntax items. 0 == infinity. https://stackoverflow.com/questions/11873767/using-folds-with-synmaxcol-in-vim

    -- UI
    -- --------------------------------------------------------------------- --

    vim.o.showcmd = false -- Show input in the status line.
    vim.o.incsearch = true -- Show search results as you type.
    vim.o.showmatch = true -- Show matching braces, etc.
    vim.o.syntax = 'on' -- Enable syntax highlighting.
    -- vim.o.filetype = 'on' -- Enables filetype detection. NOTE: Handled by filetype plugin now to avoid autocmds?

    -- TODO: Global statusline is nice, but need better way to identify individual buffers.
    vim.o.laststatus = 2 -- 2 ensures that all windows have a status line. 3 enables the global status line. -- This needs to be called before fillchars...

    vim.o.fillchars = 'eob: ' -- Remove empty buffer symbols.
    vim.o.number = false -- Hide line numbers.
    vim.o.relativenumber = false 
    vim.o.signcolumn = 'no' -- Force the signcolumn to remain hidden.
    -- vim.o.cursorline = false -- Highlight the current line. Known to cause performance issues.

    -- Lines
    -- --------------------------------------------------------------------- --

    vim.o.linebreak = true -- Wrap text on word boundaries.
    vim.o.list = false
    vim.o.wrap = false -- Wrap lines. 

    -- Indentation
    -- --------------------------------------------------------------------- --

    vim.o.autoindent = true
    vim.o.smartindent = true
    vim.o.breakindent = true -- Indent wrapped lines.
    vim.o.shiftwidth = 4 -- Num. spaces to use for each step of autoindent.
    -- vim.o.showbreak = '␤'
    -- vim.o.breakindentopt = 'shift:1'

    -- Tabs
    -- --------------------------------------------------------------------- --

    vim.o.tabstop = 4
    vim.o.expandtab = true
    vim.o.smarttab = true

    -- Timings
    -- --------------------------------------------------------------------- --

    vim.o.updatetime = 150 -- Length of time Vim waits after you stop typing before it triggers plugin.
    vim.o.ttimeoutlen = 30 -- Timeout in ms for key codes.
    vim.o.nottimeout = true
    -- vim.o.shadafile = 'NONE' -- Doesn't work?
    -- vim.o.lazyredraw = false -- Tried for perf.

    -- Folds
    -- --------------------------------------------------------------------- --

    vim.o.foldenable = true -- Make sure folds are open by default.
    vim.o.foldmethod = 'syntax'
    vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
    vim.o.foldlevel = 99

    vim.o.inccommand = 'nosplit' --Shows the effects of a command incrementally in the buffer.

    -- Window Options
    -- --------------------------------------------------------------------- --
    
    vim.w.foldcolumn = 1

    -- Hacks
    -- Coc specific flags; 'Some servers have issues with backup files'
    -- --------------------------------------------------------------------- --

    vim.opt.backup = false
    vim.opt.writebackup = false

    vim.diagnostic.config({underline = false})
    -- vim.wo.conceallevel = 1
    -- vim.wo.colorcolumn = "99999" -- Trying to solve issues with Indent Blankline

    -- Highlight yanked text on yank
    -- https://www.reddit.com/r/neovim/comments/ypvrwp/comment/ivnl294/
    vim.api.nvim_create_autocmd('TextYankPost', {
        group = vim.api.nvim_create_augroup('yank_highlight', {}),
        pattern = '*',
        callback = function ()
            vim.highlight.on_yank { higroup = 'IncSearch', timeout = 600 }
        end,
    })

    -- Vim Commands
    -- --------------------------------------------------------------------- --

    -- vim.cmd [[ set ttyfast ]]
    vim.cmd [[ set mouse=a ]] -- Enables mouse scrolling.
    vim.cmd [[ set undofile ]] -- Keep undo history between sessions.
    vim.cmd [[ autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o ]] -- Disable auto comment formatting. (`c`: auto-wrap comments; `r`: auto-insert comment leader after hitting <Enter> in Insert mode; `o`: Auto-insert the comment leader after hitting 'o' or 'O' in Normal mode.
    vim.cmd [[ let g:qs_highlight_on_keys = ['f', 'F'] ]] -- Highlight search terms on 'f' and 'F' keypresses.
    -- vim.cmd [[ au BufNewFile,BufRead *.odin map=<C-P> :w<Return>:%!odinfmt %<Return> ]]
    -- vim.cmd [[ highlight Todo guifg=#FF9E3B guibg=bg gui=bold ctermfg=178 cterm=bold ]] -- Change highlighting for todo tags.
    -- vim.cmd [[ let g:dracula_underline = 0 ]] -- Disable underlines in Dracula theme.
    -- vim.cmd [[ highlight QuickScopePrimary guifg='#c82491' gui=bold ctermfg=178 cterm=bold ]] -- Set QuickScope highlight colours.
    -- vim.cmd [[ highlight QuickScopeSecondary guifg='#afff00' ctermfg=154 ]] -- Set QuickScope secondary highlight colours.
    -- vim.cmd [[ au BufNewFile,BufRead *.odin set syntax=odin ]] -- Set Odin syntax highlighting for .odin files.
    -- vim.cmd [[ au BufNewFile,BufRead *.odin set filetype=odin ]] -- Set Odin filetype for .odin files.
    -- vim.cmd [[ au BufNewFile,BufRead *.go set syntax=go ]]
    -- vim.cmd [[ au BufNewFile,BufRead *.go set filetype=go ]]

end
