return {
    'numToStr/Comment.nvim',
    lazy = true,
    config = function(_, opts)
        require("Comment.ft").odin = { "//%s", "/*%s*/" }
        require("Comment").setup()
    end,
}
