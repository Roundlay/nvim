-- vscode.nvim

return {
    "Mofiqul/vscode.nvim",
    priority = 1000,
    opts = {
        style = "dark",
        transparent = true,
        italic_comments = false,
        underline_links = false,
    },
    config = function(_, opts)
        require("vscode").setup(opts)
        vim.cmd.colorscheme("vscode")
    end
}
