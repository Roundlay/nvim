return {
    'rebelot/kanagawa.nvim',
    enabled = true,
    lazy = false,
    priority = 1000,
    config = function(_, opts)
        require("kanagawa").setup({
            colors = kanagawa,
            theme = "default", -- Load "default" theme or the experimental "light" theme
            undercurl = true,
            commentStyle = { italic = true },
            functionStyle = { bold = true },
            keywordStyle = { italic = false },
            statementStyle = { bold = true },
            typeStyle = { bold = true },
            variablebuiltinStyle = { italic = true },
            specialReturn = true, -- Special highlight for the return keyword.
            specialException = true, -- Special highlight for exception handling keywords.
            transparent = false , -- Do not set background color.
            terminalColors = true, -- Define vim.g.terminal_color_{0,17}.
            globalStatus = true,
            dimInactive = false, 
        })
    end,
    init = function()
        vim.cmd [[ colorscheme kanagawa ]]
    end
}
