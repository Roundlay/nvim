-- copilot.vim

-- return {
--     "github/copilot.vim",
--     name = "Copilot (Vim)",
--     enabled = true,
--     lazy = true,
--     event  = "InsertEnter",
-- }

-- copilot.lua

return {
    "zbirenbaum/copilot.lua",
    name = "Copilot (Neovim)",
    enabled = true,
    lazy = true,
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter",
    opts = {
        copilot_node_command = 'node',
        server_opts_verrides = {},
        suggestion = {
            enabled = true,
            auto_trigger = true,
            debounce = 75,
            keymap = {
                accept = "<TAB>",
            },
        },
        panel = {
            enabled = true,
            auto_refresh = true,
        },
        layout = {
            position = "bottom",
            ratio = 0.4,
        },
    },
    config = function(_, opts)
        local ok, copilot = pcall(require, "copilot")
        if not ok then
          return
        end
        copilot.setup(opts)
    end
}
