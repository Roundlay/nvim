-- focus

return {
    "beauwilliams/focus.nvim",
    name = "focus",
    lazy = true,
    -- TODO How can we load whenever user opens telescope for the first time?
    -- event = "BufWinEnter",
    keys = {
        {"<leader>h", ":FocusSplitLeft<CR>", desc = "Focus Left"},
        {"<leader>j", ":FocusSplitDown<CR>", desc = "Focus Down"},
        {"<leader>k", ":FocusSplitUp<CR>", desc = "Focus Up"},
        {"<leader>l", ":FocusSplitRight<CR>", desc = "Focus Right"},
        {"<C-w>", "<C-w>", desc = "Enter Window mode"},
    },
    opts = {
        ui = {
            cursorline = false,
            cursorcolumn = false,
            signcolumn = false,
        },
    },
    config = function(_, opts)
        require("focus").setup(opts)
    end
}
