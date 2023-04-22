-- telescope.nvim

return {
    'nvim-telescope/telescope.nvim',
    name = "Telescope",
    version = false,
    lazy = true,
    cmd = 'Telescope',
    condition = function() if (vim.g.vscode) then return false end end,
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-lua/popup.nvim',
    },
    keys = {
        { ";f", "<cmd>Telescope find_files<CR>", desc = "Find file..." },
        { ";g", "<cmd>Telescope live_grep<CR>", desc = "GREP..." },
        { ";b", "<cmd>Telescope buffers<CR>", desc = "Find buffer..." },
        { ";;", "<cmd>Telescope help_tags<CR>", desc = "Display help tags..." },
        { ";c", "<cmd>Telescope commands<CR>", desc = "Display command history..." },
    },
    opts = {
        defaults = {
            layout_strategy = "bottom_pane",
            borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
            results_title = false,
            layout_config = {
                prompt_position = "bottom",
            },
        },
    },
    config = function(_, opts)
        require('telescope').setup(opts)
    end,
}
