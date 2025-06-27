-- nvim-surround

return {
    "kylechui/nvim-surround",
    version = "*",
    enabled = true,
    lazy = "true",
    -- event = "VeryLazy",
    -- event = "BufWinEnter",
    keys = {
        { "<C-e>", mode = { "n", "v", }, desc = "Activate the nvim-surround plugin in normal/visual mode." },
    },
    opts = {
        -- TODO: Add keymaps that cycle through surrounds. E.g. `<C-e>` three times for '(', four for '{', etc.
        keymaps = {
            normal = "<C-e>",
            normal_line = "<C-e>l",
            normal_cur_line = "<C-e><C-e>",
            visual = "<C-e>",
            delete = "<C-e>d",
            change = "<C-e>c",
        },
    },
    config = function(_, opts)
        local nvim_surround_ok, nvim_surround = pcall(require, "nvim-surround")
        if not nvim_surround_ok then
            vim.notify(vim.inspect(nvim_surround), vim.log.levels.ERROR)
            return
        end
        nvim_surround.setup(opts)
    end
}

