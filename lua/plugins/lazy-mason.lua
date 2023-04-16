return {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function(_, opts)
        require("mason").setup()
    end,
}
