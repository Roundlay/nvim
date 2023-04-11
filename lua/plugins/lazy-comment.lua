return {
    'numToStr/Comment.nvim',
    lazy = true,
    config = function()
        local ft = require("Comment.ft")
        ft.odin = { "//%s", "/*%s*/" }
        require("Comment").setup()
    end,
}
