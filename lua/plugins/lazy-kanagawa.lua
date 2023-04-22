return {
    'rebelot/kanagawa.nvim',
    name = "Kanagawa",
    enabled = true,
    lazy = false,
    priority = 1000,
    opts = {
        theme = "wave",
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
        globalStatus = true,
        dimInactive = false,
    },
    config = function(_, opts)
        local status_ok, kanagawa = pcall(require, "kanagawa")
        if not status_ok then
            return
        end
        kanagawa.setup(opts)
        vim.cmd.colorscheme("kanagawa")
    end,
}
