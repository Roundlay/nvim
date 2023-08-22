-- vim-colors-off

-- TODO Think about porting this to Lua slash Lualine slash Alacritty; it's 
-- pretty nice. 

return {
    "pbrisbin/vim-colors-off",
    name = "vim-colors-off",
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd.colorscheme("off")
    end
}
