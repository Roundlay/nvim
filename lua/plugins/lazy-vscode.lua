-- vscode.nvim

return {
    "Mofiqul/vscode.nvim",
    enabled = false,
    lazy = false,
    priority = 1000,
    opts = {
        style = "dark",
        transparent = false,
        italic_comments = false,
        color_overrides = {
        -- vscLineNumber = '#000000',
        },
    },
    config = function(_, opts)
        local vscode_ok, vscode = pcall(require, "vscode")
        if not vscode_ok then
            print("Error loading 'vscode.nvim'.")
            return
        end
        vscode.setup(opts)
        vim.cmd.colorscheme("vscode")
    end
}
