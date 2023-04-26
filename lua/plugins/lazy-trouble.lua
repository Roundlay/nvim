-- trouble.nvim

return {
    "folke/trouble.nvim",
    name = "trouble",
    enabled = false,
    lazy = true,
    event = "InsertEnter",
    keys = {
        {"<leader>-", "<cmd>TroubleToggle<CR>", desc = "Toggle Trouble"},
    },
    opts = {
        position = "bottom",
        padding = true,
        icons = false,
        height = 10,
        fold_open = "v",
        fold_closed = ">",
        indent_lines = true,
        signs = {
            error = "  ERROR",
            warning = "",
            hint = "",
            information = ""
        },
        use_diagnostic_signs = false -- Use the signs defined in LSP client.
    },
    config = function(_, opts)
        require("trouble").setup(opts)
    end,
}
