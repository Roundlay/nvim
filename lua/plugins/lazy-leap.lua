-- leap.nvim

return {
    "ggandor/leap.nvim",
    -- commit = "8facf2eb6a378fd7691dce8c8a7b2726823e2408", -- Temporarily rolling back to previous commit due to https://github.com/ggandor/leap.nvim/issues/171
    -- name = "leap",
    enabled = true,
    lazy = true,
    keys = {
        { "s",  mode = { "n", "x", "o" }, desc = "Leap forwards to"},
        { "S",  mode = { "n", "x", "o" }, desc = "Leap backwards to"},
        { "gs", mode = { "n", "x", "o" }, desc = "Leap from windows"},
    },
    config = function(_, opts)
        local leap_ok, leap = pcall(require, "leap")
        if not leap_ok then
            vim.notify(vim.inspect(leap), vim.log.levels.ERROR)
            return
        end

        leap.setup(opts)

        for k, v in pairs(opts) do
            leap.opts[k] = v
        end

        -- TODO: Is this still necessary?
        -- Making sure that leap.nvim doesn't override the behaviour of `x`.
        -- leap.add_default_mappings(true)
        -- vim.api.nvim_del_keymap({'v', 'x', 'o'}, 'x')
        -- vim.api.nvim_del_keymap({'v', 'x', 'o'}, 'X')

        vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward-to)", { desc = "leap-forward-to" })
        vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward-to)", { desc = "leap-backward-to" })
        vim.api.nvim_set_keymap('v', '<Plug>(leap-forward-till)', 'g', {noremap=true, silent=true}) -- E.g. `vs` then the character/s to leap to.
    end,
}
