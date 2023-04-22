-- filetype.nvim

return {
    "nathom/filetype.nvim",
    name = "Filetype",
    enabled = true,
    lazy = false,
    opts = {
        overrides = {
            extensions = {
                c = "c",
                odin = "odin",
                rs = "rust",
                py = "python",
                ipynb = "python",
                lua = "lua",
            },
        },
    },
    config = function(_, opts)
        require("filetype").setup(opts)
    end
}
