-- focus

return {
    "beauwilliams/focus.nvim",
    -- name = "focus",
    lazy = false,
    version = false,
    -- TODO How can we load whenever user opens telescope for the first time?
    -- event = {"BufEnter"},
    keys = {
        { "<C-w>", "<C-w>", desc = "Enter Window mode" },
        { "<C-v>", "<C-v>", desc = "Open file from Oil in vertical split" },
        -- If you'd prefer not to have to press <C-w> to enter window mode,you
        -- can map the following functions to your preffered navigation keys.
        -- {"<leader>h", ":FocusSplitLeft<CR>",  desc = "Focus Left"},
        -- {"<leader>j", ":FocusSplitDown<CR>",  desc = "Focus Down"},
        -- {"<leader>k", ":FocusSplitUp<CR>",    desc = "Focus Up"},
        -- {"<leader>l", ":FocusSplitRight<CR>", desc = "Focus Right"},
    },
    opts = {
        ui = {
            cursorline = false,
            cursorcolumn = false,
            signcolumn = false,
        },
        autoresize = {
            enable = true,
            minwidth = 20, -- Unfocused windows
        },

    },
    config = function(_, opts)
        local focus_ok, focus = pcall(require, "focus")
        if not focus_ok then
            vim.notify(vim.inspect(focus), vim.log.levels.ERROR)
            return
        end
        focus.setup(opts)
    end
}
