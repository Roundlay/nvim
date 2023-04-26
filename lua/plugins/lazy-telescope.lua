-- telescope.nvim

return {
    'nvim-telescope/telescope.nvim',
    name = "telescope",
    version = false,
    condition = function() if (vim.g.vscode) then return false end end,
    lazy = true,
    cmd = 'Telescope',
    keys = {
        { ";f", "<cmd>Telescope find_files<CR>", desc = "Find file..." },
        { ";g", "<cmd>Telescope live_grep<CR>", desc = "GREP..." },
        { ";b", "<cmd>Telescope buffers<CR>", desc = "Find buffer..." },
        { ";;", "<cmd>Telescope help_tags<CR>", desc = "Display help tags..." },
        { ";c", "<cmd>Telescope commands<CR>", desc = "Display command history..." },
    },
    dependencies = {
        'nvim-lua/plenary.nvim',
    },
    opts = {
        defaults = {
            layout_strategy = "bottom_pane",
            results_title = false,
            dynamic_preview_title = false,
            prompt_title = false,
            previewer = false,
            borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
            layout_config = {
                height = 0.3,
                prompt_position = "bottom",
            },
        },
    },
    config = function(_, opts)
        require('telescope').setup(opts)
    end,
}
