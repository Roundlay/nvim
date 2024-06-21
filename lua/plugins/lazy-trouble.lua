-- trouble.nvim

return {
    "folke/trouble.nvim",
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
		local trouble_ok, trouble = pcall(require, "trouble")
		if not trouble_ok then
            vim.notify(vim.inspect(trouble), vim.log.levels.ERROR)
			return
		end
        trouble.setup(opts)
    end
}
