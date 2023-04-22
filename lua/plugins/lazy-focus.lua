return {
    "beauwilliams/focus.nvim",
    name = "Focus",
    lazy = false,
    opts = {
        cursorline = false,
        signcolumn = false,
    },
    config = function(_, opts)
        require("focus").setup(opts)
    end
}
