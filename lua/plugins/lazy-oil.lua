-- oil.nvim

return {
    'stevearc/oil.nvim',
    enabled = true,
    lazy = true,
    cmd = "Oil",
    opts = {
        columns = {
            -- {"mtime", highlight = "Comment"}, -- File modification time column
        },
        buf_options = {
            buflisted = false,
            bufhidden = "hide",
        },
        keymaps = {
            ["<C-v>"] = { "actions.select_vsplit", desc = "Open the entry in vertical split" },
            ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
        },
        keymaps_help = {
            border = "none",
        },
        preview = {
            border = "none",
            win_options = {
                winblend = 1,
            },
        },
        progress = {
            border = "rounded",
        },
    },
    config = function(_, opts)
        local oil_ok, oil = pcall(require, "oil")
        if not oil_ok then
            vim.notify(vim.inspect(oil), vim.log.levels.ERROR)
            return
        end
        oil.setup(opts)
    end,
}
