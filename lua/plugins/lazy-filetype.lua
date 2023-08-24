-- filetype.nvim

return {
    "nathom/filetype.nvim",
    -- name = "filetype",
    enabled = true,
    lazy = false,
    opts = {
        overrides = {
            extensions = {
                c = "c",
                md = "markdown",
                py = "python",
                rs = "rust",
                lua = "lua",
                nim = "nim",
                txt = "text",
                odin = "odin",
                ipynb = "python",
                html = "html"
            },
            literal = {
                todos = "md",
            },
        },
    },
    config = function(_, opts)
        require("filetype").setup(opts)
    end
}
