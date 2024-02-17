-- treesitter

return {
    "nvim-treesitter/nvim-treesitter",
    -- name = "nvim-treesitter",
    enabled = true,
    version = false,
    build = ":TSUpdateSync",
    lazy = true,
    event = {
        "BufReadPost",
        "BufNewFile",
    },
    cmd = {
        "TSEnable",
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
            "markdown",
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
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "zz",
                node_incremental = "zn",
                scope_incremental = "zi",
                node_decremental = "zx",
            },
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
    config = function(_, opts)
        local nvim_treesitter_ok, nvim_treesitter = pcall(require, "nvim-treesitter.configs")
        if not nvim_treesitter_ok then
            print("Error loading `nvim_treesitter`.")
            return
        end
        -- require("nvim-treesitter.configs").setup(opts)
        nvim_treesitter.setup(opts)
    end
}
