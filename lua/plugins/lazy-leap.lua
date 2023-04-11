return {
    'ggandor/leap.nvim',
    enabled = true,
    config = function ()
        require("leap").add_default_mappings()
    end,
    init = function ()
        vim.keymap.del({'x', 'o'}, 'x')
        vim.keymap.del({'x', 'o'}, 'X')
        vim.api.nvim_set_keymap('v', 'g', '<Plug>(leap-forward-till)', {noremap=true, silent = true}) -- Fixes leap's remapping of x in visual mode.
    end,
}
