-- kanagawa.nvim

return {
    'rebelot/kanagawa.nvim',
    -- name = "kanagawa",
    enabled = true,
    lazy = false,
    priority = 1000,
    opts = {
        theme = "wave",
        overrides = function(colors)
            local theme = colors.theme
            return {
                Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
                PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
                PmenuSbar = { bg = theme.ui.bg_m1 },
                PmenuThumb = { bg = theme.ui.bg_p2 },
            }
        end,
        undercurl = true,
        commentStyle = { italic = false },
        functionStyle = { bold = true },
        keywordStyle = { italic = false },
        statementStyle = { bold = true },
        typeStyle = { bold = true },
        variablebuiltinStyle = { italic = true },
        specialReturn = true, -- Special highlight for the return keyword.
        specialException = true, -- Special highlight for exception handling keywords.
        transparent = false , -- Do not set background color.
        terminalColors = true, -- Define vim.g.terminal_color_{0,17}.
        globalStatus = false,
        dimInactive = false,
    },
    config = function(_, opts)
        local kanagawa_ok, kanagawa = pcall(require, "kanagawa")
        if not kanagawa_ok then
            return
        end
        kanagawa.setup(opts)
        vim.cmd.colorscheme("kanagawa")
    end,
}
