-- NOTES:

-- 'nvim-lspconfig' does not set keybindings or enable completion
-- by default. The following example configuration provides suggested
-- keymaps for the most commonly used language server functions,
-- and manually triggered completion with omnifunc (<c-x><c-o>).

-- You must pass the defined `on_attach` as an argument to every
-- `setup{}` call and the keybindings in `on_attach` only take effect
-- on buffers with an active language server.

return {
    'neovim/nvim-lspconfig',
    enabled = true,
    event = 'BufReadPre',
    dependencies = {
        'mason.nvim', -- Defined in mason.nvim.lua
        'mason-lspconfig.nvim' -- Defined in mason-lspconfig.nvim.lua
    },
}
