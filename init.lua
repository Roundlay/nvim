-- init.lua
-- -------------------------------------------------------------------------- --

-- Benchmarks
-- -------------------------------------------------------------------------- --

-- Lazy Benchmark (29-08-23)
-- Lazy Profile: Startuptime: 31.21ms
-- Environment: Windows 11 -> Alacritty (Administrator) -> Clink -> NVIM v0.9.1
-- Command: `hyperfine --warmup 5 "nvim init.lua --headless +qa"`

-- Vim-Plug Benchmark (22-04-23)
-- Environment: Windows 11 -> Alacritty (Administrator) -> Clink -> NVIM v0.9.0
-- Command: `hyperfine --warmup 5 "nvim init.lua --headless +qa"`
-- Time (mean ± σ):    279.6 ms ±   6.2 ms  [User: 108.4 ms, System: 201.6 ms]
-- Range (min … max):  274.5 ms … 295.2 ms  10 runs

-- Initialisation
-- -------------------------------------------------------------------------- --

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- WSL detection
-- TODO: Document this.
local function is_wsl()
    local proc_version = '/proc/version'
    if vim.fn.filereadable(proc_version) == 1 then
        local content = vim.fn.readfile(proc_version, '', 1)
        return content[1] and content[1]:lower():match('microsoft') ~= nil
    end
    return false
end

vim.g.is_wsl = is_wsl()

-- Markdown plain mode affects Treesitter attach decisions, so it must exist
-- before Lazy evaluates plugin setup and any FileType-driven module attach.
vim.g.markdown_plain_mode = true

do
    local treesitter_start = vim.treesitter.start

    vim.treesitter.start = function(bufnr, lang)
        local target_bufnr = bufnr or 0
        if target_bufnr == 0 then
            target_bufnr = vim.api.nvim_get_current_buf()
        end

        local filetype = vim.bo[target_bufnr].filetype
        if vim.g.markdown_plain_mode and (
            filetype == "markdown"
            or lang == "markdown"
            or lang == "markdown_inline"
        ) then
            return
        end

        return treesitter_start(bufnr, lang)
    end
end

require("lazy-init")
require("settings")
require("autocmds")

vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
        pcall(require, "scripts")
        pcall(require, "keybindings")
        pcall(require, "highlights")
    end,
})

vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function()
        pcall(require, "scripts.numberline")
    end,
})
