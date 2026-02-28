-- oil.nvim

return {
    'stevearc/oil.nvim',
    opts = {
        columns = {
            "icon",
        },
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
            is_hidden_file = function(name, bufnr)
                return vim.startswith(name, ".")
            end,
            is_always_hidden = function(name, bufnr)
                return false
            end,
        },
        git = {
            -- Return true to automatically git add/mv/rm files
            add = function(path)
                return false
            end,
            mv = function(src_path, dest_path)
                return false
            end,
            rm = function(path)
                return false
            end,
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

        require("oil").setup(opts)
    end,
}
