return {
    'rebelot/kanagawa.nvim',
    enabled = true,
    lazy = false,
    priority = 1000,
    opts = {
        theme = "dragon", -- "wave", "lotus", "dragon"
        overrides = function(colors)
            local theme = colors.theme
            return {
                Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
                PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
                PmenuSbar = { bg = theme.ui.bg_m1 },
                PmenuThumb = { bg = theme.ui.bg_p2 },
            }
        end,
        compile = true,
        undercurl = true,
        commentStyle = { italic = false },
        functionStyle = { bold = true },
        keywordStyle = { italic = false },
        statementStyle = { bold = false },
        typeStyle = { bold = false },
        variablebuiltinStyle = { italic = false },
        specialReturn = true, -- Special highlight for the return keyword.
        specialException = true, -- Special highlight for exception handling keywords.
        transparent = false, -- Do not set background color.
        terminalColors = true, -- Define vim.g.terminal_color_{0,17}.
        globalStatus = false,
        dimInactive = true,
        background = {
            dark = "wave",
            light = "lotus"
        },
    },
    config = function(_, opts)
        local kanagawa_ok, kanagawa = pcall(require, "kanagawa")
        if not kanagawa_ok then
            vim.notify(vim.inspect(kanagawa), vim.log.levels.ERROR)
            return
        end
        kanagawa.setup(opts)
        vim.cmd.colorscheme("kanagawa")
    end,
}
