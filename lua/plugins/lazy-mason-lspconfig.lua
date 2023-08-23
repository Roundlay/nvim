-- mason-lspconfig.nvim

-- Notes:
-- It's important that this be called after `mason.nvim`.
-- Set up servers via `lspconfig`.

return {
    "williamboman/mason-lspconfig.nvim",
    name = "mason-lspconfig.nvim",
    lazy = true,
    dependencies = {
        "neovim/nvim-lspconfig",
        "williamboman/mason.nvim",
    },
    config = function()
		local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
		if not mason_lspconfig_ok then
			return
		end
        mason_lspconfig.setup()
    end,
}
