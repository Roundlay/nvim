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

require("perf.init")
local perf_lazy = require("perf.lazy")

local function collect_plugin_specs()
    local specs = {}
    local config_dir = vim.fn.stdpath("config") .. "/lua/plugins"
    local handle = vim.loop.fs_scandir(config_dir)
    if not handle then
        return specs
    end
    local modules = {}
    while true do
        local name, file_type = vim.loop.fs_scandir_next(handle)
        if not name then
            break
        end
        if file_type == "file" and name:sub(-4) == ".lua" then
            modules[#modules + 1] = name:sub(1, -5)
        end
    end
    table.sort(modules)
    for i = 1, #modules do
        local module_name = "plugins." .. modules[i]
        local ok, spec = pcall(require, module_name)
        if ok and type(spec) == "table" then
            if type(spec[1]) == "string" then
                perf_lazy.instrument(spec, module_name)
                specs[#specs + 1] = spec
            else
                for _, entry in ipairs(spec) do
                    if type(entry) == "table" then
                        perf_lazy.instrument(entry, module_name)
                        specs[#specs + 1] = entry
                    end
                end
            end
        elseif not ok then
            vim.schedule(function()
                vim.notify("Failed to load plugin spec " .. module_name .. ": " .. tostring(spec), vim.log.levels.ERROR)
            end)
        end
    end
    return specs
end

local plugin_specs = collect_plugin_specs()

-- Lazy Setup

require("lazy").setup(plugin_specs, {
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
