-- focus.nvim

return {
    "beauwilliams/focus.nvim",
    version = false,
    keys = {
        { "<C-w>", "<C-w>", desc = "Enter Window mode" },
        { "<C-v>", "<C-v>", desc = "Open file from Oil in vertical split" },
    },
    opts = {
        ui = { number = false, signcolumn = false, cursorline = false },
        autoresize = { 
            enable = true, 
            minwidth = 40,  -- Default focus.nvim behavior
            width = 0,     -- Use remaining space for focused window
            height = 0,    -- Don't change height
        },
    },
}
