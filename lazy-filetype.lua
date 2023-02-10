return {
    'nathom/filetype.nvim',
    enabled = true,
    lazy = false,
    config = require("filetype").setup({
        overrides = {
            extensions = {
                odin = 'odin',
                rs = 'rust',
                py = 'python',
                ipynb = 'python',
                lua = 'lua',
            },
        },
    })
}
