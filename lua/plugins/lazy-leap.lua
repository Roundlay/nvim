return {
    "ggandor/leap.nvim",
    name = "Leap",
    enabled = true,
    lazy = true,
    event = "InsertEnter",
    keys = {
        { "s", mode = { "n", "x", "o" }, desc = "Leap forwards to" },
        { "S", mode = { "n", "x", "o" }, desc = "Leap backwards to" },
        { "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
    },
    config = function(_, opts)
        local leap = require("leap")
        for k, v in pairs(opts) do
            leap.opts[k] = v
        end
        leap.add_default_mappings(true)
        vim.keymap.del({'x', 'o'}, 'x')
        vim.keymap.del({'x', 'o'}, 'X')
        vim.api.nvim_set_keymap('v', '<Plug>(leap-forward-till)', 'g', {noremap=true, silent=true})
    end,
}
