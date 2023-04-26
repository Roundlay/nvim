return {
    "williamboman/mason-lspconfig.nvim",
    name = "mason-lspconfig",
    lazy = true,
    config = function()
		local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
		if not mason_lspconfig_ok then
			return
		end
        mason_lspconfig.setup()
    end,
}
