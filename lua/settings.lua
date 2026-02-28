if vim.g.vscode then
    vim.o.clipboard = 'unnamed,unnamedplus' -- Use both the system clipboard and the local clipboard.
    return
end

vim.g.markdown_plain_mode = true

if vim.g.neovide then
    -- See: https://neovide.dev/configuration.html
    vim.o.guifont = "Berkeley Mono"
    vim.o.linespace = 1
    vim.g.neovide_cursor_animation_length = 0.01
    vim.g.neovide_cursor_trail_size = 0.02
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

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_tutor = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tar = 1

vim.o.hidden = true
vim.o.mouse = 'a'
vim.o.timeoutlen = 500
vim.o.ttimeoutlen = 0
vim.o.termsync = true
vim.o.termguicolors = true
vim.o.redrawtime = 500

-- @TODO: Consider using XDG_CONFIG_HOME and XDG_DATA_HOME? What about Windows though? Look into this.
NVIM_STATE = vim.fn.stdpath('state')
-- @TODO: SHADA_DIRECTORY is referenced in autocmds.lua... I don't like this... Should everything be in one file?
SHADA_DIRECTORY = NVIM_STATE .. '/shada' -- Set the directory for shada files.
vim.fn.mkdir(SHADA_DIRECTORY, 'p') -- Create dir if missing.
vim.opt.shadafile = SHADA_DIRECTORY .. ('/main-%d.shada'):format(vim.fn.getpid()) -- Write unique temp. files so that force-closing a window never collides with another instance.

local undo_dir = NVIM_STATE .. '/undo' -- Set the directory for undo files.
vim.fn.mkdir(undo_dir, 'p') -- Create dir if missing.
vim.opt.undofile = true -- Save undo history to a file for persistence across sessions.
vim.opt.undodir = undo_dir
vim.opt.undolevels = 1000000 -- Maximum number of undo levels to keep.
vim.opt.undoreload = 1000000 -- Number of lines to save for undo history.

vim.o.smoothscroll = true
vim.o.number = true
vim.o.cursorline = false
vim.o.signcolumn = 'no'
vim.o.fillchars = 'eob: ,vert:│'
vim.cmd('hi! link WinSeparator Normal')
-- vim.o.winborder = "solid"

vim.o.linebreak = true
vim.o.breakindent = true
vim.o.wrap = true

vim.o.laststatus = 2
vim.o.showmode = false
-- NOTE: showcmd=false causes tearing artifacts when Neovim runs in tmux splits (2025-12-30)
-- The issue does not occur in standalone tmux windows (no splits).
-- Likely a tmux pane synchronization conflict. Leaving at default (true).
-- vim.o.showcmd = false

vim.o.incsearch = true
vim.o.hlsearch = true
vim.o.showmatch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.inccommand = 'nosplit'

vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = false

vim.o.foldmethod = 'syntax'
vim.o.foldlevel = 99

vim.o.splitright = true

-- TODO: Move to autocmds file
vim.api.nvim_create_autocmd("LspAttach", {
    once = true,
    callback = function()
        if vim.lsp and vim.lsp.handlers then
            vim.lsp.handlers["workspace/didChangeWatchedFiles"] = { dynamic_registration = true }
        end
    end,
})

vim.o.clipboard = "" -- "Do not tie `""` to either the `"+` or the `"*` registers."
vim.o.shortmess = vim.o.shortmess .. "I" -- Don't show the intro message when starting Neovim.
