-- nvim-surround

return {
    "kylechui/nvim-surround",
    version = "*",
    lazy = true,
    event = "CmdlineEnter",
    init = function()
        -- nvim-surround v4 removes `setup({ keymaps = ... })`; use custom maps
        -- via <Plug> targets and disable defaults before plugin load.
        vim.g.nvim_surround_no_mappings = true
    end,
    keys = {
        { "<C-e>", "<Plug>(nvim-surround-normal)", mode = "n", desc = "Add a surrounding pair around a motion." },
        { "<C-e>l", "<Plug>(nvim-surround-normal-line)", mode = "n", desc = "Add a surrounding pair around a motion on new lines." },
        { "<C-e><C-e>", "<Plug>(nvim-surround-normal-cur-line)", mode = "n", desc = "Add a surrounding pair around the current line on new lines." },
        { "<C-e>", "<Plug>(nvim-surround-visual)", mode = "x", desc = "Add a surrounding pair around a visual selection." },
        { "<C-e>d", "<Plug>(nvim-surround-delete)", mode = "n", desc = "Delete a surrounding pair." },
        { "<C-e>c", "<Plug>(nvim-surround-change)", mode = "n", desc = "Change a surrounding pair." },
    },
}
