-- local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- if not vim.loop.fs_stat(lazypath) then
--     vim.fn.system({
--         "git",
--         "clone",
--         "--filter=blob:none",
--         "https://github.com/folke/lazy.nvim.git",
--         "--branch=stable", -- latest stable release
--         lazypath,
--     })
-- end
-- vim.opt.rtp:prepend(lazypath)

-- vim.g.mapleader = ' '
-- vim.g.maplocalleader = ' '

-- require("lazy").setup("plugins", {
--     change_detection = {
--         enabled = true,
--         notify = false,
--     },
--     ui = {
--         icons = {
--             cmd = "COMMAND",
--             config = "CONFIG",
--             event = "EVENT",
--             ft = "TYPE",
--             init = "INIT",
--             keys = "KEYS",
--             plugin = "PLUGIN",
--             runtime = "RUNTIME",
--             source = "SOURCE",
--             start = "START",
--             task = "TASK",
--             lazy = "",
--         },
--     },
-- })

require('settings')
require('plugins')
require('keybindings')
require('highlights')
