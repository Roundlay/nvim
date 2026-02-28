-- bufferline.nvim

return {
    'akinsho/bufferline.nvim', 
    version = "*", 
    enabled = false,
    lazy = true,
    event = "BufWinEnter",
    opts = {
        options = {
            numbers = "buffer_id",
            buffer_close_icon = "⨯",
            close_icon = "⨯",
        },
    },
}
