return {
    'numToStr/Comment.nvim',
    config = true
    init = function()
        local ft = require("Comment.ft")
        ft.odin = { "//%s", "/*%s*/" }
    end,
}
