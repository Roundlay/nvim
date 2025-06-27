-- orgmode.lua

return {
    'nvim-orgmode/orgmode',
    enabled = false,
    lazy = true,
    event = "VeryLazy",
    ft = { "org" },
    opts = {
        org_agenda_files = '~/orgfiles/**/*',
        org_default_notes_file = '~/orgfiles/refile.org',
    },
    config = function(_, opts)
        local orgmode_ok, orgmode = pcall(require, "orgmode")
        if not orgmode_ok then
            vim.notify(vim.inspect(orgmode), vim.log.levels.ERROR)
            return
        end
        orgmode.setup(opts)
    end,
}
