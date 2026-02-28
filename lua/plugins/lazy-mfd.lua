return {
    'kungfusheep/mfd.nvim',
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function(_, opts)
        require("mfd")
        vim.cmd('colorscheme mfd-amber')
    end
}
