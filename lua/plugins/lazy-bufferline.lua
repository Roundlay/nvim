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
    config = function (_, opts)
        local bufferline_ok, bufferline = pcall(require, "bufferline")
        if not bufferline_ok then
            vim.notify(vim.inspect(bufferline), vim.log.levels.ERROR)
            return
        end
        bufferline.setup(opts)
    end
}
