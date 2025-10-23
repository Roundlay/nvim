-- lazy-init.lua
-- -----------------------------------------------------------------------------

-- Notes:
-- Lazy has some issues with the 'name' parameter. Custom names often result in
-- duplicate entries in the Lazy dashboard when that plugin is listed by another
-- plugin as a dependency. This is presumably because you can only use the full
-- git path as the dependency name, which ends up listed on the dashboard.

if vim.g.vscode then
    return
end

-- Lazy Installation

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

-- Note: Set up the leader key before Lazy tries to set itself up. I do that
-- in 'keybindings.lua'.
-- vim.g.mapleader = ' '
-- vim.g.maplocalleader = ' '

-- Lazy Setup

require("lazy").setup("plugins", {
    -- The directory where Lazy installs plugins.
    root = vim.fn.stdpath("data") .. "/lazy",
    -- The statefile contains information used by Lazy's checker feature.
    state = vim.fn.stdpath("state") .. "/lazy/state.json",
    -- The lockfile contains a list of installed plugins and revisions.
    -- It's recommended to keep this file in a directory under version control,
    -- as `:Lazy restore` uses this file to restore/update plugins to the
    -- versions specified within it.
    lockfile = vim.fn.stdpath("config") .. "/lua/" .. "lazy-lock.json",
    defaults = {
        lazy = false
    },
    change_detection = {
        enabled = true,
        notify = false,
    },
    checker = {
        enabled = true,
        concurrency = nil,
        notify = false,
        frequencey = 3600,
    },
    performance = {
        cache = {
            enabled = true,
        },
        rtp = {
            disabled_plugins = {
                "gzip",
                "netrw",
                "tohtml",
                "tutor",
                "netrwPlugin",
                "tarPlugin",
                "zipPlugin",
                "rplugin",
                "matchit",
                "matchparen",
                "osc52",
                "spellfile",
                "man",
                "editorconfig",
            },
        },
        reset_packpath = true,
    },
    ui = {
        size = {
            width = 1.0,
            height = 1.0,
        },
        wrap = true,
        border = "solid",
        icons = {
            cmd = "COMMAND",
            config = "CONFIG",
            event = "EVENT",
            ft = "TYPE",
            init = "INIT",
            import = "IMPORT",
            keys = "KEYS",
            lazy = "",
            loaded = "●",
            not_loaded = "○",
            plugin = "PLUGIN",
            runtime = "RUNTIME",
            source = "SOURCE",
            start = "START",
            task = "TASK",
            list = {
                "-",
                "-",
                "-",
                "-",
                "-",
            },
        },
    },
})
