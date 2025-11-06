-- oil.nvim

return {
    'stevearc/oil.nvim',
    enabled = true,
    lazy = true,
    cmd = "Oil",
    opts = {
        adapters = {
            ["oil://"] = "files",
            ["oil-ssh://"] = false,
            ["oil-trash://"] = false,
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
            update_on_move = false,
            border = "none",
            win_options = {
                winblend = 1,
            },
        },
        view_options = {
            show_hidden = false,
            natural_order = "fast",
        },
        float = {
            padding = 2,
            max_width = 0.33,
        },
        confirmation = {
            max_width = 0.33,
            border = "none",
        },
    },
    config = function(_, opts)
        -- TODO: Doesn't even work?
        -- Declare a global function to retrieve the current directory
        function _G.get_oil_winbar()
          local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
          local dir = require("oil").get_current_dir(bufnr)
          if dir then
            return vim.fn.fnamemodify(dir, ":~")
          else
            -- If there is no current directory (e.g. over ssh), just show the buffer name
            return vim.api.nvim_buf_get_name(0)
          end
        end

        local oil_ok, oil = pcall(require, "oil")
        if not oil_ok then
            vim.notify(vim.inspect(oil), vim.log.levels.ERROR)
            return
        end
        oil.setup(opts)
    end,
}
