-- filetype.nvim

return {
    "nathom/filetype.nvim",
    enabled = false,
    lazy = false,
    opts = {
        overrides = {
            extensions = {
                odin = "odin",
                xml = "xml",
                c = "c",
                md = "markdown",
                py = "python",
                rs = "rust",
                lua = "lua",
                nim = "nim",
                txt = "text",
                html = "html",
                ipynb = "python",
                sh = "bash",
                xit = "xit",
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
