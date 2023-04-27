return {
    'numToStr/Comment.nvim',
    name = "comment",
    lazy = true,
    keys = {
        { "gcc", "gcc", desc = "Toggle blockwise comment" },
        { "gc", "gcc", desc = "Toggle blockwise comment" },
    },
    opts = {
        padding = true,
        sticky = true,
        mappings = {
            basic = true
        }, -- Setup custom mappings as listed above.
    },
    config = function(_, opts)
        require("Comment").setup(opts)
        require("Comment.ft").odin = { "//%s", "/*%s*/" } -- Define custom comment syntax for Odin files.
    end,
}
