return {
    "nvim-treesitter/nvim-treesitter",
    enabled = true,
    version = false,
    build = ":TSUpdateSync",
    lazy = true,
    event = {
        "VimEnter",
        -- "BufReadPre",
    },
    cmd = {
        "TSEnable",
    },
    -- dependencies = {
    --     "nvim-treesitter/nvim-treesitter-textobjects",
    -- },
    opts = {
        -- ensure_installed = {
        --     "c",
        --     "lua",
        --     "vim",
        --     "vimdoc",
        --     "query",
        --     "rust",
        --     "odin",
        --     "cmake",
        --     "python",
        --     "markdown",
        --     "javascript",
        -- },
        sync_install = false,
        auto_install = true,
        highlight = {
            enable = true, -- Highlighting incredibly slow when this is false.
            additional_vim_regex_highlighting = false, -- Slow.
        },
        indent = {
            enable = false -- Experimental and broke indentation in Odin.
        },
        -- playground = {
        --     enable = true,
        --     disable = {},
        --     updatetime = 25,
        --     persist_queries = true,
        --     keybindings = {
        --         toggle_query_editor = "o",
        --         toggle_hl_groups = "i",
        --         toggle_injected_languages = "t",
        --         toggle_anonymous_nodes = "a",
        --         toggle_language_display = "I",
        --         focus_language = "f",
        --         unfocus_language = "F",
        --         update = "R",
        --         goto_node = "<cr>",
        --         show_help = "?",
        --     },
        -- },
    },
    config = function(_, opts)
        local nvim_treesitter_ok, nvim_treesitter = pcall(require, "nvim-treesitter.configs")
        if not nvim_treesitter_ok then
            print("Error loading `nvim_treesitter`.")
            return
        end
        nvim_treesitter.setup(opts)
    end
}
