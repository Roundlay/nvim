return {
    'nvim-treesitter/nvim-treesitter',
    version = false,
    build = ':TSUpdate',
    event = 'BufReadPost',
    keys = {
    },
    config = function ()
        require('nvim-treesitter.configs').setup({
            ensure_installed = 'all',
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true }, -- Broke indentation in Odin
            context_commentstring = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = {},
            },
            playground = {
                enable = true,
                disable = {},
                updatetime = 25,
                persist_queries = false,
                keybindings = {
                    toggle_query_editor = 'o',
                    toggle_hl_groups = 'i',
                    toggle_injected_languages = 't',
                    toggle_anonymous_nodes = 'a',
                    toggle_language_display = 'I',
                    focus_language = 'f',
                    unfocus_language = 'F',
                    update = 'R',
                    goto_node = '<cr>',
                    show_help = '?',
                },
            },
        })
    end,
}
