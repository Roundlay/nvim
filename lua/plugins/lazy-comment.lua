-- Comment.nvim

return {
    'numToStr/Comment.nvim',
    lazy = true,
    keys = {
        {"gcc", mode = {"n"}, desc = "Toggle linewise comment"},
        {"gc", mode = {"v"}, desc = "Toggle blockwise comment"},
    },
    opts = {
        padding = true,
        sticky = true,
        mappings = {
            basic = true
        },
    },
}
