return {
    "xiyaowong/transparent.nvim",
    enabled = false,
    -- priority = 1000,
    opts = {
        -- table: default groups
        groups = {
            'Normal', 'NormalNC', 'Comment', 'Constant', 'Special', 'Identifier',
            'Statement', 'PreProc', 'Type', 'Underlined', 'Todo', 'String', 'Function',
            'Conditional', 'Repeat', 'Operator', 'Structure', 'LineNr', 'NonText',
            'SignColumn', 'CursorLineNr', 'StatusLine', 'StatusLineNC',
            'EndOfBuffer',
        },
        -- table: additional groups that should be cleared
        extra_groups = {"NormalFloat", "TelescopeBorder", "WinSeparator", "VertSplit"},
        -- table: groups you don't want to clear
        exclude_groups = {"TelescopeSelection", "TelescopeSelectionCaret",},
        -- function: code to be executed after highlight groups are cleared
        -- Also the user event "TransparentClear" will be triggered
        on_clear = function() end,
    },
    config = function(_, opts)
        local transparent_ok, transparent = pcall(require, "transparent")
        if not transparent_ok then
            vim.notify(vim.inspect(transparent), vim.log.levels.ERROR)
            return
        end
        transparent.setup(opts)
    end,
}
