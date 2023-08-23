-- mason.nvim

-- Incomming dependencies: nvim-lspconfig
-- Outgoing dependencies: mason-lspconfig

return {
    "williamboman/mason.nvim",
    -- name  = "mason",
    build = ":MasonUpdate",
    lazy  = true,
    event = "BufReadPre",
    cmd   = "Mason",
    keys = {
        -- { "<leader>mm", "<cmd>Mason<CR>", desc = "Toggle Mason Menu" },
    },
    opts = {
        ui = {
            border = "none",
        },
    },
    config = function(_, opts)
        -- NOTE You were experimenting with ability to hot-load plugins?
		local mason_ok, mason = pcall(require, "mason")
		if not mason_ok then
			return
		end
        mason.setup(opts)
        -- require("mason").setup(opts)
    end,
}
