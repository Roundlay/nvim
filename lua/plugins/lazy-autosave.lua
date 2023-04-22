return {
    'Pocco81/auto-save.nvim',
    name = "Autosave",
    enabled = true,
    lazy = true,
    condition = function() if (vim.g.vscode) then return false end end,
    event = "InsertEnter",
    opts = {
        enabled = true,
        write_all_buffers = false,
        execution_message = {
            message = function() return ('Auto-Saved at '..vim.fn.strftime('%H:%M:%S')) end,
            dim = 0.33,
        },
    },
    config = function(_, opts)
        require('auto-save').setup(opts)
    end,
}
