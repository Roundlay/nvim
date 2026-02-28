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
}
