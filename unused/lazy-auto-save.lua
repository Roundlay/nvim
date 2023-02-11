return {
    'Pocco81/auto-save.nvim',
    enabled = true,
    config = function()
        require('auto-save').setup {
            enabled = true,
            execution_message = {
                    message = function() return ('Auto-Saved at '..vim.fn.strftime('%H:%M:%S')) end,
                    dim = 0.33,
            },
            write_all_buffers = false,
        },
    end,
}
