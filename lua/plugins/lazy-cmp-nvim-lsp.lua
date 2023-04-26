-- cmp-nvim-lsp

return {
    "hrsh7th/cmp-nvim-lsp",
    name = "cmp-nvim-lsp",
    enable = true,
    lazy = true,
    config = function()
        cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
		if not cmp_nvim_lsp_ok then
			return
		end
        -- local capabilities = vim.lsp.protocol.make_client_capabilities()
        -- capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
    end,
}
