return {
    "williamboman/mason.nvim",
    name = "Mason",
    build = ":MasonUpdate",
    cmd = "Mason",
    event = "BufReadPre",
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
    },
    opts = {
        ui = {
            border = "none",
        },
    },
    config = function(_, opts)

		local mason_ok, mason = pcall(require, "mason")
		if not mason_ok then
			return
		end

		local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
		if not mason_lspconfig_ok then
			return
		end

        mason.setup(opts)

    end,
}
