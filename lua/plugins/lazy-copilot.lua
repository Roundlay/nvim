-- copilot.vim

-- NOTE: This can't be lazy loaded at the moment because it doesn't play nicely with telescope and <Tab>.

-- return {
--     "github/copilot.vim",
--     name = "copilot",
--     enabled = true,
--     -- lazy = false,
--     -- event  = "InsertEnter", -- 23/4/23: Not compatible with telescope and causes issues with tab functionality.
-- }

-- copilot.lua

-- NOTE: Doesn't support tab completion in the same way the Vim plugin does.

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
            debounce = 300,
            keymap = {
                accept = "<S-0>",
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
        local copilot_ok, copilot = pcall(require, "copilot")
        if not copilot_ok then
          return
        end
        copilot.setup(opts)

        -- Super Tab allows for tab completion in the same way the Vim plugin does.
        vim.keymap.set('i', '<Tab>', function()
            if require("copilot.suggestion").is_visible() then
                require("copilot.suggestion").accept()
            else
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
            end
        end, { desc = "Super Tab" })
    end
}
