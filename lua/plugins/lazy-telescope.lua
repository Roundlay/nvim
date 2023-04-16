return {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope', -- Lazy load the plugin when the `Telescope` command is executed
    version = false,
    keys = {
        { ";f", ":Telescope find_files<CR>" }, 
        { ";g", ":Telescope live_grep<CR>" },
        { ";b", ":Telescope buffers<CR>" },
        { ";;", ":Telescope help_tags<CR>" },
    },
    config = function(_, opts)
        require('telescope').setup()
    end,
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-lua/popup.nvim',
    },
}
