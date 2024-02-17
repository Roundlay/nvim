-- tree-sitter-markdown

return {
    "MDeiml/tree-sitter-markdown",
    enabled = true,
    lazy = true,
    event = "BufReadPost",
    ft = "markdown",
    dependencies = {
        "nvim-treesitter/nvim-treesitter"
    },
    config = function()
        -- Annotate `parser_config` as a class for type checking and intellisense.
        -- This is necessary to define the structure expected by Neovim's tree-sitter integration,
        -- enabling safe injection of parser configurations like `markdown`.
        ---@class parser_config -- Type annotation
        local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
        parser_config.markdown = {
            install_info = {
                url = "C:/Users/Christopher/AppData/Local/nvim-data/lazy/tree-sitter-markdown/tree-sitter-markdown",
                files = {
                    "src/parser.c",
                    "src/scanner.c"
                },
            },
            filetype = "markdown",
        }
    end
}
