-- Comment.nvim

return {
    'numToStr/Comment.nvim',
    enabled = true,
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
    config = function(_, opts)
		local comment_ok, comment = pcall(require, "Comment")
		if not comment_ok then
            vim.notify(vim.inspect(comment), vim.log.levels.ERROR)
			return
		end
        comment.setup(opts)
    end
}
