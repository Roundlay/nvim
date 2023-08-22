-- treesitter

return {
    "nvim-treesitter/nvim-treesitter",
    name = "nvim-treesitter",
    enabled = true,
    version = false,
    build = ":TSUpdateSync",
    lazy = true,
    event = "BufReadPost",
    cmd = {
        "TSEnable",
    },
    dependencies = {
        "nvim-treesitter/playground",
    },
    opts = {
        ensure_installed = {
            "c",
            "lua",
            "vim",
            "rust",
            "odin",
            "cmake",
            "query",
            "python",
        },
        sync_install = false,
        auto_install = false,
        highlight = {
            enable = true, -- Highlighting incredibly slow when this is false.
            additional_vim_regex_highlighting = false, -- Slow.
        },
        text_objects = {
            enable = true
        },
        indent = {
            enable = false -- Experimental and broke indentation in Odin.
        },
        playground = {
            enable = true,
            disable = {},
            updatetime = 25,
            persist_queries = true,
            keybindings = {
                toggle_query_editor = "o",
                toggle_hl_groups = "i",
                toggle_injected_languages = "t",
                toggle_anonymous_nodes = "a",
                toggle_language_display = "I",
                focus_language = "f",
                unfocus_language = "F",
                update = "R",
                goto_node = "<cr>",
                show_help = "?",
            },
        },
    },
    config = function (_, opts)
        require("nvim-treesitter.configs").setup(opts)
    end
}
