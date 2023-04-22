local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require("lazy").setup("plugins", {
    -- Directory where Lazy plugins will be installed.
    root = vim.fn.stdpath("data") .. "/lazy",
    state = vim.fn.stdpath("state") .. "/lazy/state.json",
    -- Move the lock-file to the lua subdirectory.
    lockfile = vim.fn.stdpath("config") .. "/lua/" .. "lazy-lock.json",
    defaults = {
        lazy = false,
    },
    -- install = {
    --     missing = true,
    --     colorscheme = {"kanagawa"},
    -- },
    change_detection = {
        enabled = true,
        notify = false,
    },
    checker = {
        enabled = false,
        concurrency = nil,
        notify = true,
        frequencey = 3600,
    },
    performance = {
        cache = {
            enabled = true,
        },
        reset_packpath = true,
    },
    readme= {
    },
    ui = {
        icons = {
            cmd = "COMMAND",
            config = "CONFIG",
            event = "EVENT",
            ft = "TYPE",
            init = "INIT",
            keys = "KEYS",
            plugin = "PLUGIN",
            runtime = "RUNTIME",
            source = "SOURCE",
            start = "START",
            task = "TASK",
            lazy = "",
        },
    },
})
