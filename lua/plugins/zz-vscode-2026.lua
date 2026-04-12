local theme = require("themes.vscode_2026_dark")

return {
    "Mofiqul/vscode.nvim",
    opts = function(_, opts)
        opts = opts or {}
        opts.transparent = false
        opts.color_overrides = vim.tbl_extend("force", opts.color_overrides or {}, theme.color_overrides)
        opts.group_overrides = vim.tbl_extend("force", opts.group_overrides or {}, theme.group_overrides)
        return opts
    end,
}
