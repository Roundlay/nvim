-- copilot.vim

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

-- Note: For the Alacritty slash modified-carriage-return enjoyers out there,
-- to get <S-CR> and <C-CR> working, Alacritty needs to be configured to send
-- escape-sequences Vim expects: https://stackoverflow.com/a/42461580/21730427

return {
    "zbirenbaum/copilot.lua",
    name = "Copilot (Neovim)",
    enabled = true,
    build = ":Copilot auth",
    lazy = true,
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
        copilot_node_command = 'node',
        server_opts_verrides = {},
        suggestion = {
            enabled = true,
            auto_trigger = true,
            debounce = 1,
            keymap = {
                accept = "<C-CR>",
                -- accept = "<S-CR>",
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
    },
    config = function(_, opts)
        local copilot_ok, copilot = pcall(require, "copilot")
        if not copilot_ok then
          return
        end
        copilot.setup(opts)

        -- This keymap makes accepting suggestions work similarly to the
        -- official Copilot plugin, allowing you to use <Tab> for
        -- indentation as well as for accepting Copilot suggestions.

        -- vim.keymap.set('i', '<S-CR>', function()
        --     if require("copilot.suggestion").is_visible() then
        --         require("copilot.suggestion").accept()
        --     else
        --         vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        --     end
        -- end, {desc = "Super Tab"})
    end
}
