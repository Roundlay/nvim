-- mason.nvim

return {
    "williamboman/mason.nvim",
    -- name  = "mason",
    build = ":MasonUpdate",
    lazy = true,
    cmd = "Mason",
    opts = {
        ui = {
            border = "none",
        },
    },
    config = function(_, opts)
		local mason_ok, mason = pcall(require, "mason")
		if not mason_ok then
            vim.notify(vim.inspect(mason), vim.log.levels.ERROR)
			return
		end
        mason.setup(opts)
    end,
}
