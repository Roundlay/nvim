-- marks.nvim

return {
    "chentoast/marks.nvim",
    enabled = false,
    event = "VeryLazy",
    lazy = true,
    config = function()
        local marks_ok, marks = pcall(require, "marks")
        if not marks_ok then
            vim.notify(vim.inspect(luasnip), vim.log.levels.ERROR)
            return
        end
    end,
}
