return {
    'nathom/filetype.nvim',
    enabled = true,
    lazy = false,
    opts = {
        overrides = {
            extensions = {
                odin = 'odin',
                rs = 'rust',
                py = 'python',
                ipynb = 'python',
                lua = 'lua',
            },
        },
    },
    config = function(_, opts)
        require("filetype").setup(opts)
    end
}
