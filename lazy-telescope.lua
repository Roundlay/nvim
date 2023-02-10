return {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope', -- Lazy load the plugin when the `Telescope` command is executed
    version = 0.1.0, -- TODO: What about `tag`?
    config = function()
        require('telescope').setup()
    end,
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-lua/popup.nvim',
    },
    -- keys = {
        -- { "<leader>,", "<cmd>Telescope buffers show_all_buffers=true<cr>", desc = "Switch Buffer" },
    -- },
    -- opts = {
    --     defaults = {
    --         prompt_prefix = "",
    --         selection_caret = "",
    --         mappings = {
    --         }
    --     },
    -- },
}
