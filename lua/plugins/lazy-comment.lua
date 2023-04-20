return {
    'numToStr/Comment.nvim',
    lazy = true,
    opts = {
        padding  = true,
        sticky   = true,
        mappings = { basic = true },
    },
    config = function(_, opts)
        require("Comment").setup()
        require("Comment.ft").odin = { "//%s", "/*%s*/" }
    end,
}
