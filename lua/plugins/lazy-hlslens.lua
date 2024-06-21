-- nvim-hlslens

return {
    "kevinhwang91/nvim-hlslens",
    enabled = false,
    lazy = true,
    event = "BufReadPre",
    opts = {
        calm_down = true,
        nearest_float_when = "never",
    },
    config = function(_, opts)
		local hlslens_ok, hlslens = pcall(require, "hlslens")
		if not hlslens_ok then
            vim.notify(vim.inspect(hlslens), vim.log.levels.ERROR)
			return
		end
        hlslens.setup(opts)
    end,
}
