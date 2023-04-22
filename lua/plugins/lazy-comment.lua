return {
    'numToStr/Comment.nvim',
    name = "Comment",
    lazy = true,
    event = "BufEnter", -- Lazy load Comment.nvim when user enters Insert Mode for the first time.
    opts = {
        padding  = true,
        sticky   = true,
        mappings = { basic = true },
    },
    config = function(_, opts)
        require("Comment").setup(opts)
        require("Comment.ft").odin = { "//%s", "/*%s*/" } -- Define custom comment syntax for Odin files.
    end,
}
