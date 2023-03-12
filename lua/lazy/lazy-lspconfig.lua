return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    opts = {},
    config = function(plugin, opts)
        -- require("nvim-lspconfig")...
    end
}
