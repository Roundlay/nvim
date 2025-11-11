-- autocmds.lua
--------------------------------------------------------------------------------

-- Custom autocommands for Neovim to automate behaviors based on events.
-- Auto-commands grouped here instead of per-file to avoid target ambiguity.
-- E.g. Should the auto-command that hides Copilot when Blink menus are open
-- be in the Blink or Copilot plugin file? Placing it here avoids that question.

-- VIM

-- Remove temporary shada files on VimEnter.
vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
        for _, f in ipairs(vim.fn.glob(SHADA_DIRECTORY..'/main-*.shada.tmp.*', 0, 1)) do
            os.remove(f)
        end
    end
})

-- Highlight yanked text on yank.
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('yank_highlight', {}),
    pattern = '*',
    callback = function()
        vim.highlight.on_yank { higroup = 'IncSearch', timeout = 300 }
    end,
})

-- Disable auto-comments by removing 'c', 'r', and 'o' from `formatoptions` for
-- all filetypes.
vim.api.nvim_create_autocmd('FileType', {
    pattern = '*',
    callback = function()
        vim.opt_local.formatoptions:remove({'c', 'r', 'o'})
    end,
})

-- Enter insert mode and move cursor to end of line when opening or switching to
-- a terminal.
vim.api.nvim_create_autocmd({'TermOpen', 'WinEnter'}, {
    pattern = '*',
    callback = function()
        if vim.bo.buftype == 'terminal' and vim.fn.mode() ~= 'i' then
            vim.api.nvim_win_set_cursor(0, {vim.fn.line('$'), vim.fn.col('$')})
            vim.cmd('startinsert')
        end
    end,
})

-- Exit insert mode when leaving a terminal.
vim.api.nvim_create_autocmd('WinLeave', {
    pattern = '*',
    callback = function()
        if vim.bo.buftype == 'terminal' then
            vim.cmd('stopinsert')
        end
    end,
})

-- PLUGINS

-- COPILOT + BLINK.CMP INTEGRATION

-- Hide Copilot suggestion when BlinkCmp menu is open.
vim.api.nvim_create_autocmd("User", {
  pattern = "BlinkCmpMenuOpen",
  callback = function()
    vim.b.copilot_suggestion_hidden = true
  end,
})

-- Show Copilot suggestion when BlinkCmp menu is closed.
vim.api.nvim_create_autocmd("User", {
  pattern = "BlinkCmpMenuClose",
  callback = function()
    vim.b.copilot_suggestion_hidden = false
  end,
})

-- FOCUS

-- Disable focus autoresize for filetypes 'oil' and 'lazy'.
local ignore_filetypes = { 'oil', 'lazy' }
vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    callback = function(_)
        if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
            vim.b.focus_disable = true
        else
            vim.b.focus_disable = false
        end
    end,
    desc = 'Disable focus autoresize for oil and lazy filetypes.',
})

-- WSL INTEGRATION

-- TODO!
-- WSL Clipboard sync - DISABLED to keep registers separate
-- Commented out to allow separate Neovim and system clipboard usage
-- Regular y/p use Neovim registers, <leader>y/<leader>p use system clipboard
-- if vim.g.is_wsl then
--     -- Sync with system clipboard on focus gain
--     vim.api.nvim_create_autocmd({ "FocusGained" }, {
--         pattern = { "*" },
--         command = [[call setreg("@", getreg("+"))]],
--         desc = 'Sync system clipboard to default register on focus gain in WSL'
--     })
--
--     -- Sync with system clipboard on focus lost
--     vim.api.nvim_create_autocmd({ "FocusLost" }, {
--         pattern = { "*" },
--         command = [[call setreg("+", getreg("@"))]],
--         desc = 'Sync default register to system clipboard on focus lost in WSL'
--     })
-- end

-- WORKSPACE LINE ENDINGS

-- Force LF endings inside the rdpad workspace so Neovim never writes CRLF (^M) when editing from either Windows or WSL.
local workspace_unix_ff = vim.api.nvim_create_augroup('workspace_unix_fileformat', { clear = true })

local function normalize_path(path)
    return path:gsub('\\', '/'):lower()
end

local workspace_root_variants = {
    '/mnt/c/Users/Christopher/rdpad/',
    'c:/users/christopher/rdpad/',
}

local workspace_root_paths = {}
local workspace_root_lengths = {}

for i = 1, #workspace_root_variants do
    local normalized = normalize_path(workspace_root_variants[i])
    workspace_root_paths[i] = normalized
    workspace_root_lengths[i] = #normalized
end

local workspace_root_count = #workspace_root_paths

local function is_workspace_path(normalized_path)
    for i = 1, workspace_root_count do
        if normalized_path:sub(1, workspace_root_lengths[i]) == workspace_root_paths[i] then
            return true
        end
    end

    return false
end

vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    group = workspace_unix_ff,
    callback = function(event)
        local name = vim.api.nvim_buf_get_name(event.buf)
        if name == '' then
            return
        end

        local normalized = normalize_path(name)
        if not is_workspace_path(normalized) then
            return
        end

        local buf_opts = vim.bo[event.buf]

        -- 'fileformat' is buffer-local; coercing it is sufficient to force LF writes.
        if buf_opts.fileformat ~= 'unix' then
            buf_opts.fileformat = 'unix'
        end
    end,
    desc = 'Clamp rdpad workspace files to LF endings when editing from Windows or WSL.',
})

-- local swift_lsp = vim.api.nvim_create_augroup("swift_lsp", { clear = true })
-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = { "swift" },
-- 	callback = function()
-- 		local root_dir = vim.fs.dirname(vim.fs.find({
-- 			"Package.swift",
-- 			".git",
-- 		}, { upward = true })[1])
-- 		local client = vim.lsp.start({
-- 			name = "sourcekit-lsp",
-- 			cmd = { "sourcekit-lsp" },
-- 			root_dir = root_dir,
-- 		})
-- 		vim.lsp.buf_attach_client(0, client)
-- 	end,
-- 	group = swift_lsp,
-- })
