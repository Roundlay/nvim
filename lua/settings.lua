-- settings.lua

if vim.g.vscode then
    vim.o.clipboard = 'unnamed,unnamedplus' -- Use both the system clipboard and the local clipboard.
    return
end

if vim.g.neovide then
    -- See: https://neovide.dev/configuration.html
    vim.o.guifont = "Pragmasevka:h14"
    vim.o.linespace = 1
    vim.g.neovide_cursor_animation_length = 0.02
    vim.g.neovide_cursor_trail_size = 0.05
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

NVIM_STATE = vim.fn.stdpath('state')
-- TODD: SHADA_DIRECTORY is referenced in autocmds.lua... I don't like this... Should everything be in one file?
SHADA_DIRECTORY = NVIM_STATE .. '/shada' -- Set the directory for shada files.

vim.fn.mkdir(SHADA_DIRECTORY, 'p') -- Create dir if missing.
vim.opt.shadafile = SHADA_DIRECTORY .. ('/main-%d.shada'):format(vim.fn.getpid()) -- Write unique temp. files so that force-closing a window never collides with another instance.

local undo_dir = NVIM_STATE .. '/undo' -- Set the directory for undo files.
vim.fn.mkdir(undo_dir, 'p') -- Create dir if missing.
vim.opt.undofile = true -- Save undo history to a file for persistence across sessions.
vim.opt.undodir = undo_dir
vim.opt.undolevels = 1000000 -- Maximum number of undo levels to keep.
vim.opt.undoreload = 1000000 -- Number of lines to save for undo history.

-- Standard Plugins
-- Tell Vim's 'standard plugins' to finish early. In other words, mark these as
-- loaded to prevent them from eating into startup time when `rtp plugins` are
-- sourced. Note: This isn't always reliable as they may still load.
-- See: `:h standard-plugin`, `:h standard-plugin-list`, `:h load-plugins`.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_tutor = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tar = 1

-- Core Environment
vim.g.hidden = true
vim.g.mouse = 'a'
vim.g.timeoutlen = 500
vim.g.ttimeoutlen = 0
vim.g.redrawtime = 1

-- Display
vim.o.number = true
vim.o.cursorline = false
vim.o.signcolumn = 'no'
vim.o.fillchars = 'eob: ,vert:│'

-- Text Formatting
vim.o.linebreak = true
vim.o.breakindent = true
vim.o.wrap = true

-- Colors

-- Status Line
vim.o.laststatus = 2
vim.o.showcmd = false
vim.o.showmode = false

-- Search
vim.o.incsearch = true
vim.o.hlsearch = true
vim.o.showmatch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.inccommand = 'nosplit'

-- Indentation
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = false

-- Folds
vim.o.foldmethod = 'syntax'
vim.o.foldlevel = 99

-- Buffers
vim.o.splitright = true

-- LSP and Diagnostics
-- vim.diagnostic.config({ underline = false })          -- Disable underlining for diagnostics.
vim.lsp.handlers["workspace/didChangeWatchedFiles"] = { dynamic_registration = true } -- Enable dynamic file watching.

-- WSL Clipboard Configuration
-- if vim.fn.has('wsl') == 1 then
--     local clipboard_cache = { content = '', timestamp = 0 }
--     local cache_ttl = 100  -- Cache for 100ms to reduce calls
--     
--     local function get_clipboard()
--         local now = vim.loop.hrtime() / 1000000  -- Convert to milliseconds
--         if now - clipboard_cache.timestamp < cache_ttl and clipboard_cache.content then
--             return vim.split(clipboard_cache.content, '\n')
--         end
--         
--         local handle = io.popen('win32yank.exe -o --lf 2>/dev/null')
--         if handle then
--             local result = handle:read('*a') or ''
--             handle:close()
--             clipboard_cache.content = result
--             clipboard_cache.timestamp = now
--             return vim.split(result, '\n')
--         end
--         return {''}
--     end
--     
--     local function set_clipboard(lines)
--         local content = table.concat(lines, '\n')
--         clipboard_cache.content = content
--         clipboard_cache.timestamp = vim.loop.hrtime() / 1000000
--         
--         -- Use job API for non-blocking copy
--         vim.fn.jobstart({'win32yank.exe', '-i', '--crlf'}, {
--             stdin = 'pipe',
--             on_stdin = function(_, data, _)
--                 if data then
--                     for _, line in ipairs(data) do
--                         vim.fn.chansend(_, line)
--                     end
--                     vim.fn.chanclose(_, 'stdin')
--                 end
--             end
--         })
--     end
--     
--     if vim.fn.executable('win32yank.exe') == 1 then
--         vim.g.clipboard = {
--             name = 'win32yank-wsl-optimized',
--             copy = {
--                 ['+'] = set_clipboard,
--                 ['*'] = set_clipboard,
--             },
--             paste = {
--                 ['+'] = get_clipboard,
--                 ['*'] = get_clipboard,
--             },
--             cache_enabled = 1,
--         }
--     end
-- end

vim.o.clipboard = "" -- "Do not tie `""` to either the `"+` or the `"*` registers."
vim.o.shortmess = vim.o.shortmess .. "I" -- Don't show the intro message when starting Neovim.

-- Make background transparent:
vim.cmd [[
    highlight Normal guibg=NONE ctermbg=NONE
    highlight NonText guibg=NONE ctermbg=NONE
    highlight SignColumn guibg=NONE ctermbg=NONE
    highlight EndOfBuffer guibg=NONE ctermbg=NONE
]]


vim.o.fileformat = "unix"
-- vim.cmd [[autocmd BufWritePre * setlocal fileformat=unix]]

-- ARCHIVE

-- Open files in tabs
-- [ ] Doesn't work.
-- vim.api.nvim_create_autocmd("BufNewFile,BufRead", {
--     pattern = "*",
--     callback = function()
--         if #vim.api.nvim_list_wins() >= 1 then
--             vim.cmd("tabnew")
--         end
--     end,
-- })

-- vim.cmd [[ let g:dracula_underline = 0:]] -- Disable underlines in Dracula theme.
