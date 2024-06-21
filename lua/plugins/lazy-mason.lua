-- mason.nvim

return {
    "williamboman/mason.nvim",
    lazy = true,
    build = ":MasonUpdate",
    cmd = "Mason",
    opts = {
        ui = {
            border = "none",
        },
        PATH = "prepend",
    },
    config = function(_, opts)
		local mason_ok, mason = pcall(require, "mason")
		if not mason_ok then
            vim.notify(vim.inspect(mason), vim.log.levels.ERROR)
			return
		end
        mason.setup(opts)
    end
}
