-- An init.lua example:
-- https://github.com/mukeshsoni/config/blob/master/.config/nvim/init.lua

-- Echo Neovim's runtimepath variables.
-- print(vim.inspect(vim.api.nvim_list_runtime_paths()))

if (vim.g.vscode) then

    -- Visual Studio Code Settings

    vim.cmd([[ let g:qs_highlight_on_keys = ['f', 'F'] ]])

    -- Colours based on: https://icolorpalette.com/color/pantone-16-0836-tcx
    -- vim.cmd([[
    --     highlight QuickScopePrimary guifg='#c8b273'
    --     highlight QuickScopeSecondary guifg='#73c7b2'
    -- ]])

else

    -- Neovim Settings

    -- Global Options

    -- Netrw

    vim.g.loaded_netrw = 1 -- netrw is Neovim's built in file explorer
    vim.g.loaded_netrwPlugin = 1
    -- vim.g.netrw_banner = 0
    -- vim.g.netrw_liststyle = 3
    -- vim.g.netrw_browse_split = 3 -- Open new files from netrw in a new tab.
    -- vim.g.netrw_winsize = 20

    -- Options

    vim.o.encoding = 'utf-8'
    vim.o.termguicolors = true -- Enable true 24bit colour support; required for custom Neovim theme.
    vim.o.background = 'dark'

    vim.o.hidden = true -- Retain undo information when a buffer is unloaded (incl. ToggleTerm)
    vim.o.showcmd = false -- Show input in the status line.

    vim.o.showmatch = true -- Show matching braces, etc.
    vim.o.ignorecase = true -- Ignore case when searching.
    vim.o.smartcase = true -- Don't ignore case with capitals.
    vim.o.hlsearch = true -- Highlight search results.
    vim.o.incsearch = true -- Show search results as you type.
    vim.o.synmaxcol = 10000 -- Max columns (letters) to search for syntax items.

    vim.o.syntax = 'on' -- Enable syntax highlighting.
    vim.o.filetype = 'on'
    vim.o.fillchars = 'eob: ' -- Remove empty buffer symbols.
    vim.o.foldenable = false -- Make sure folds are open by default.
    vim.o.laststatus = 2 -- Ensures that all windows have a status line.
    vim.o.number = false -- Hide line numbers.
    vim.o.relativenumber = false 
    vim.o.signcolumn = 'no' -- Force the signcolumn to remain hidden.

    vim.o.linebreak = true -- Wrap text on word boundaries.
    vim.o.list = false
    vim.o.wrap = false -- Wrap lines. 

    vim.o.autoindent = true
    vim.o.smartindent = true
    vim.o.breakindent = true -- Indent wrapped lines.
    vim.o.shiftwidth = 4 -- Num. spaces to use for each step of autoindent.
    -- vim.o.showbreak = '␤'
    -- vim.o.breakindentopt = 'shift:1'

    vim.o.tabstop = 4
    vim.o.expandtab = true
    vim.o.smarttab = true

    vim.o.updatetime = 150 -- Length of time Vim waits after you stop typing before it triggers plugin.
    vim.o.ttimeoutlen = 50 -- Timeout in ms for key codes.
    -- vim.o.shadafile = 'NONE' -- Doesn't work?
    -- vim.o.lazyredraw = true -- Tried for perf.

    vim.o.foldmethod = 'expr'
    vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
    vim.o.inccommand = 'nosplit' --Shows the effects of a command incrementally in the buffer.

    -- Window Options

    vim.w.foldcolumn = 1

    --- Hacks

    vim.diagnostic.config({underline = false})
    -- vim.wo.conceallevel = 1
    -- vim.wo.colorcolumn = "99999" -- Trying to solve issues with Indent Blankline

    -- Highlight yanked text
    -- https://www.reddit.com/r/neovim/comments/ypvrwp/comment/ivnl294/
    vim.api.nvim_create_autocmd('TextYankPost', {
        group = vim.api.nvim_create_augroup('yank_highlight', {}),
        pattern = '*',
        callback = function ()
            vim.highlight.on_yank { higroup = 'IncSearch', timeout = 600 }
        end,
    })

    vim.cmd [[ set mouse=a ]] -- Enables mouse scrolling.
    vim.cmd [[ set undofile ]] -- Keep undo history between sessions.
    vim.cmd [[ let g:dracula_underline = 0 ]] -- Disable underlines in Dracula theme.
    vim.cmd [[ let g:qs_highlight_on_keys = ['f', 'F'] ]] -- Highlight search terms on 'f' and 'F' keypresses.
    vim.cmd [[ highlight QuickScopePrimary guifg='#c82491' gui=bold ctermfg=178 cterm=bold ]] -- Set QuickScope highlight colours.
    vim.cmd [[ highlight QuickScopeSecondary guifg='#afff00' ctermfg=154 ]] -- Set QuickScope secondary highlight colours.
    -- vim.cmd [[ au BufNewFile,BufRead *.odin set syntax=odin ]] -- Set Odin syntax highlighting for .odin files.
    -- vim.cmd [[ au BufNewFile,BufRead *.odin set filetype=odin ]] -- Set Odin filetype for .odin files.
    -- vim.cmd [[ au BufNewFile,BufRead *.go set syntax=go ]] -- Set Odin filetype for .odin files.
    -- vim.cmd [[ au BufNewFile,BufRead *.go set filetype=go ]] -- Set Odin filetype for .odin files.

end
