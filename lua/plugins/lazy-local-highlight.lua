-- local-highlight.nvim
-- Highlights all instances of the word under the cursor.
-- Highlight latency is determined by `vim.o.updatetime`, which represents 
-- the speed in ms that Neovim writes the swap-file to disk.

return {
    "tzachar/local-highlight.nvim",
    enabled = false,
    lazy = true,
    version = false,
    event = "BufReadPost",
    condition = function() if (vim.g.vscode) then return false end end,
    opts = {
        disable_file_types = { "terminal", }, -- Exclude terminal buffers and empty filetypes
        hlgroup = "Search",
        cw_hlgroup = "CurSearch", -- Specify highlight group for word under cursor
        insert_mode = false,
        min_match_len = 1,
        max_match_len = math.huge,
        highlight_single_match = true,
        debounce_timeout = 1,
    },
    config = function(_, opts)
        local local_highlight_ok, local_highlight = pcall(require, "local-highlight")
        if not local_highlight_ok then
            vim.notify(vim.inspect(local_highlight), vim.log.levels.ERROR)
            return
        end
        local_highlight.setup(opts)
    end
}
