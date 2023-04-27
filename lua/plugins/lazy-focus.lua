-- focus

return {
    "beauwilliams/focus.nvim",
    name = "focus",
    lazy = true,
    -- event = "BufWinEnter",
    keys = {
        {"<leader>h", ":FocusSplitLeft<CR>", desc = "Focus Left"},
        {"<leader>j", ":FocusSplitDown<CR>", desc = "Focus Down"},
        {"<leader>k", ":FocusSplitUp<CR>", desc = "Focus Up"},
        {"<leader>l", ":FocusSplitRight<CR>", desc = "Focus Right"},
        {"<C-w>", "<C-w>", desc = "Enter Window mode"},
    },
    opts = {
        cursorline = false,
        signcolumn = false,
    },
    config = function(_, opts)
        require("focus").setup(opts)
    end
}
