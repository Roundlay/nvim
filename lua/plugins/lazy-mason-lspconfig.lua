return {
    "williamboman/mason-lspconfig.nvim",
    -- build = ":MasonUpdate",
    config = function(_, opts)

        require("mason-lspconfig").setup()
    end,
}
