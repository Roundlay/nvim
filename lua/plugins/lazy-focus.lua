-- focus.nvim

return {
    "beauwilliams/focus.nvim",
    lazy = true,
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
    config = function(_, opts)
        local focus_ok, focus = pcall(require, "focus")
        if not focus_ok then
            vim.notify(vim.inspect(focus), vim.log.levels.ERROR)
            return
        end
        focus.setup(opts)
    end
}
