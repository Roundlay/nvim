-- mason-lspconfig.nvim

-- Notes:

-- Incomming dependencies: neovim/nvim-lspconfig
-- Outgoing dependencies: mason.nvim
-- It's important that this be called after `mason.nvim` and before `lspconfig`.
-- Lazy's dependencies are a little counterjntuitive. The `dependencies` field
-- defines what plugins must be loaded before the plugin listing the dependency.
-- Load order: mason.nvim -> mason-lspconfig.nvim -> lspconfig
-- Dependency flow: lspconfig -> mason.nvim <- mason-lspconfig.nvim

return {
    "williamboman/mason-lspconfig.nvim",
    -- name = "mason-lspconfig.nvim",
    lazy = true,
    dependencies = {
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
