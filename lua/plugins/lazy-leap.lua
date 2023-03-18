return {
    'ggandor/leap.nvim',
    config = function ()
        require("leap").add_default_mappings()
    end,
    -- It's not clear if it's appropriate to define keybindings here.
    -- These are from keybindings.lua.
    init = function ()
        -- Leap is a died-in-the-wool never-x-er so I'm deleting x here so that Leap's take on x doesn't get in the way of my x-ing.
        vim.keymap.del({'x', 'o'}, 'x')
        vim.keymap.del({'x', 'o'}, 'X')
        vim.api.nvim_set_keymap('v', 'g', '<Plug>(leap-forward-till)', {noremap=true, silent = true}) -- Fixes leap's remapping of x in visual mode.
    end,
}
