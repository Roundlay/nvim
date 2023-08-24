-- playground

return {
    "nvim-treesitter/playground",
    -- name = "playground",
    enabled = true,
    lazy = true,
    cmd = {
        "TSPlaygroundToggle",
        "TSPlayground",
    },
    opts = {
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
