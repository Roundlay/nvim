return {
    'lukas-reineke/indent-blankline.nvim',
    name = "Indent Blankline",
    enabled = true,
    lazy = false,
    config = function ()
        require("indent_blankline").setup {
            char = "┃",
            char_blankline = "┋",
            show_current_context = false,
            show_current_context_start = false,
            show_end_of_line = true,
            show_first_indent_level = true,
            show_foldtext = true,
            show_trailing_blankline_indent = true,
            strict_tabs = false,
            use_treesitter = true, -- Was causing some issues with .odin files.
            use_treesitter_scope = true,
        }
    end,
}
