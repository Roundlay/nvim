-- vscode.nvim

return {
    "Mofiqul/vscode.nvim",
    name = "vscode",
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
        local kanagawa_ok, kanagawa = pcall(require, "vscode")
        if not kanagawa_ok then
            return
        end
        kanagawa.setup(opts)
        vim.cmd.colorscheme("vscode")
    end
}
