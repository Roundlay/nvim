return {
    'ggandor/leap.nvim',
    enabled = true,
    keys = {
        { "s", mode = { "n", "x", "o" }, desc = "Leap forwards to" },
        { "S", mode = { "n", "x", "o" }, desc = "Leap backwards to" },
        { "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
    },
    config = function(_, opts)
        require("leap").add_default_mappings()
        vim.keymap.del({'x', 'o'}, 'x')
        vim.keymap.del({'x', 'o'}, 'X')
        vim.api.nvim_set_keymap('v', '<Plug>(leap-forward-till)', 'g', {noremap=true, silent=true})
    end,
}
