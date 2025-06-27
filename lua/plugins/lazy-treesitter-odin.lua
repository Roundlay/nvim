-- tree-sitter-odin

-- [ ] TODO Wrappin: Add option that disables wrapping on filepaths and long unbroken strings.

-- The files in the plugin directory (e.g., "C:\...\nvim-data\lazy\nvim-treesitter-odin\queries") 
-- need to be place in or symlinked to the after/queries directory *in your config directory*,
-- where your config directory is the one containing 'init.lua', etc.
-- E.g., "C:\Users\Christopher\AppData\Local\nvim\after\queries\odin".
-- Make sure the Odin filetype is correctly recognised by Neovim. 

return {
    "ap29600/tree-sitter-odin",
    enabled = false,
    condition = function() if (vim.g.vscode) then return false end end,
    lazy = true,
    ft = "odin",
    dependencies = {
        "nvim-treesitter/nvim-treesitter"
    },
    config = function()
        --- @class parser_config
        local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
        parser_config.odin = {
            install_info = {
                -- url = "C:/Users/Christopher/AppData/Local/nvim-data/lazy/nvim-treesitter-odin",
                url = "C:/Users/Christopher/scoop/apps/neovim/current/share/nvim/runtime/queries/odin",
                branch = 'main',
                files = "src/parser.c",
            },
            filetype = "odin",
        }
    end
}
