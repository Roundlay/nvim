-- settings.lua

if vim.g.vscode then
    vim.o.clipboard = 'unnamed,unnamedplus' -- Use both the system clipboard and the local clipboard.
    return
end

if vim.g.neovide then
    -- See: https://neovide.dev/configuration.html
    vim.o.guifont = "SF Mono:h14"
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

local tmux_version_cache
local tmux_sixel_support_cache

local function systemlist_quiet(cmd)
    local ok, output = pcall(vim.fn.systemlist, cmd)
    if not ok then
        return nil
    end
    local status = vim.v.shell_error
    return {
        output = output,
        status = status,
    }
end

local function tmux_version_info()
    if tmux_version_cache ~= nil then
        return tmux_version_cache
    end

    local result = systemlist_quiet('tmux -V 2>/dev/null')
    if not result or result.status ~= 0 or not result.output or #result.output == 0 then
        tmux_version_cache = false
        return tmux_version_cache
    end

    local normalized = table.concat(result.output, ' '):gsub('%s+', ' ')
    local lower = normalized:lower()
    local major, minor = lower:match('(%d+)%.(%d+)')

    tmux_version_cache = {
        major = major and tonumber(major) or nil,
        minor = minor and tonumber(minor) or nil,
        raw = lower,
        edge = lower:find('master', 1, true) ~= nil or lower:find('next%-', 1, true) ~= nil,
    }

    return tmux_version_cache
end

local function tmux_version_has_sixel_fix()
    local info = tmux_version_info()
    if not info or info == false then
        return false
    end
    if info.edge then
        return true
    end
    if not info.major or not info.minor then
        return false
    end
    return info.major > 3 or (info.major == 3 and info.minor >= 6)
end

local function tmux_supports_sixel_passthrough()
    if tmux_sixel_support_cache ~= nil then
        return tmux_sixel_support_cache
    end

    local result = systemlist_quiet('tmux display-message -p "#{client_termfeatures}" 2>/dev/null')
    if not result or result.status ~= 0 or not result.output or #result.output == 0 then
        tmux_sixel_support_cache = false
        return tmux_sixel_support_cache
    end

    local features = table.concat(result.output, ' '):lower()
    tmux_sixel_support_cache = features:find('sixel', 1, true) ~= nil
    return tmux_sixel_support_cache
end

local function tmux_needs_sixel_workaround()
    if vim.env.NVIM_TMUX_SIXEL_WORKAROUND == '0' then
        return false
    end
    if not vim.env.TMUX then
        return false
    end
    if vim.env.NVIM_TMUX_SIXEL_WORKAROUND == '1' then
        return true
    end
    if not tmux_supports_sixel_passthrough() then
        return false
    end

    -- tmux#4488 fixes the DECRQSS/SIXEL mix-up by requiring zero intermediates
    -- before dispatching the SIXEL parser. Until that ships in a release
    -- (tmux 3.6+), keep suppressing Neovim's cursor queries inside tmux.
    if tmux_version_has_sixel_fix() then
        return false
    end
    return true
end

if tmux_needs_sixel_workaround() then
    vim.opt.guicursor = ''
    vim.g.tmux_sixel_workaround = true
end

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
-- vim.o.fillchars = 'eob: ,vert:│'
vim.o.fillchars = 'eob: ,vert:,'

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
vim.api.nvim_create_autocmd("LspAttach", {
    once = true,
    callback = function()
        if vim.lsp and vim.lsp.handlers then
            vim.lsp.handlers["workspace/didChangeWatchedFiles"] = { dynamic_registration = true }
        end
    end,
})

-- TODO: Test this clipboard caching again later.
-- Description: Optimize clipboard operations in WSL by caching clipboard content
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
