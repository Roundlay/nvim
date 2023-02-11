return {
    'folke/trouble.nvim',
    enabled = true,
    lazy = true,
    config = function()
        -- NOTE: Disable underlines with `vim.diagnostic.config({ underline = false })`
        require('trouble').setup {
            icons = false,
        }
    end,
}
