-- copilot.vim
-- -----------------------------------------------------------------------------

-- Note: This can't be lazy-loaded at the moment because the plugin doesn't play
-- nicely with telescope and <Tab>...?

-- return {
--     "github/copilot.vim",
--     name = "copilot",
--     enabled = true,
--     lazy = true,
--     event = "InsertEnter", 
-- }

-- copilot.lua
-- -----------------------------------------------------------------------------

-- For the Alacritty slash modified-carriage-return enjoyers out there, to get
-- <S-CR> and <C-CR> working, Alacritty needs to be configured to send escape
-- sequences Vim expects: https://stackoverflow.com/a/42461580/21730427

return {
    "zbirenbaum/copilot.lua",
    build = ":Copilot auth",
    enabled = true,
    lazy = true,
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
        copilot_node_command = 'node',
        copilot_model = "gpt-4o-copilot",
        workspace_folders = {
          "C:\\Users\\Christopher\\scoop\\apps\\odin\\current\\examples",
        },
        filetypes = {
            markdown = false,
            text = false,
        },
        server_opts_overrides = {},
        suggestion = {
            enabled = true,
            auto_trigger = true,
            debounce = 1,
            keymap = {
                accept = false,
            },
        },
        panel = {
            enabled = false,
            auto_refresh = true,
        },
        layout = {
            position = "bottom",
            ratio = 0.4,
        },
      root_dir = function()
        return vim.fs.dirname(vim.fs.find(".git", { upward = true })[1])
      end,
    },
    config = function(_, opts)
        local copilot_ok, copilot = pcall(require, "copilot")
        if not copilot_ok then
            vim.notify(vim.inspect(copilot), vim.log.levels.ERROR)
            return
        end
        copilot.setup(opts)

        -- Set up keybindings to accept Copilot suggestions
        local accept_suggestion = function()
            require("copilot.suggestion").accept()
        end
        
        -- Standard <C-CR> - requires proper terminal configuration
        vim.keymap.set('i', '<C-CR>', accept_suggestion, {desc = "Accept Copilot suggestion"})
        
        -- Keep C-\ as backup
        vim.keymap.set('i', '<C-\\>', accept_suggestion, {desc = "Accept Copilot suggestion (backup)"})
    end
}
