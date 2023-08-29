-- cmp-nvim-lsp

return {
    "hrsh7th/cmp-nvim-lsp",
    -- name = "cmp-nvim-lsp",
    enable = true,
    lazy = true,
    config = function()
        local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
		if not cmp_nvim_lsp_ok then
			return
		end
    end,
}
