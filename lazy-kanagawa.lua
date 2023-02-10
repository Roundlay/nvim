return {
    'rebelot/kanagawa.nvim',
    enabled = true,
    lazy = false,
    config = function()
        require('kanagawa').setup({
            colors = kanagawa,
            undercurl = true,
            typeStyle = { bold = true },
            commentStyle = { italic = false },
            terminalColors = true,
            globalStatus = false,
            dimInactive = true,
        })
    end,
    init = function()
        vim.cmd [[ colorscheme kanagawa ]]
    end
}
