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

if vim.loader and vim.loader.enable then
    vim.loader.enable()
end

-- WSL detection
local function is_wsl()
    local proc_version = '/proc/version'
    if vim.fn.filereadable(proc_version) == 1 then
        local content = vim.fn.readfile(proc_version, '', 1)
        return content[1] and content[1]:lower():match('microsoft') ~= nil
    end
    return false
end

vim.g.is_wsl = is_wsl()

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
        pcall(require, "pretty_line_numbers")
    end,
})
