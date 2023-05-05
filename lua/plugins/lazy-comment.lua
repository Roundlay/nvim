return {
    'numToStr/Comment.nvim',
    name = "comment",
    lazy = true,
    event = "BufReadPost",
    keys = {
        { "gcc", "gcc", desc = "Toggle linewise comment" },
        { "gc", "gc", desc = "Toggle blockwise comment" },
    },
    opts = {
        padding = true,
        sticky = true,
        mappings = {
            basic = true
        },
    },
    config = function(_, opts)
        require("Comment").setup(opts)
    end,
}
