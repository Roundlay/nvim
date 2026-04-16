return {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdateSync",
    opts = {
        sync_install = false,
        auto_install = false,
        ensure_installed = {
            "c",
            "lua",
            "odin",
            "query",
            "toml",
            "vimdoc",
        },
        ignore_install = {},
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
            -- Plain-mode markdown should never attach treesitter first and
            -- then try to tear it down in ftplugin; disable the highlighter
            -- at the source so scheduled parser work never starts.
            disable = function(lang)
                if not vim.g.markdown_plain_mode then
                    return false
                end
                return lang == "markdown" or lang == "markdown_inline"
            end,
        },
    },
    config = function(_, opts)
        local nvim_treesitter = require("nvim-treesitter.configs")
        if opts.auto_install then
            -- Avoid auto-install errors for parsers that require tree-sitter generate.
            local has_ts_cli = vim.fn.executable("tree-sitter") == 1
            local has_node = vim.fn.executable("node") == 1
            if not (has_ts_cli and has_node) then
                local ignore = {}
                local parser_ok, parsers = pcall(require, "nvim-treesitter.parsers")
                if parser_ok then
                    local parser_configs = parsers.get_parser_configs()
                    for lang, config in pairs(parser_configs) do
                        local install_info = config.install_info
                        if install_info and install_info.requires_generate_from_grammar then
                            ignore[#ignore + 1] = lang
                        end
                    end
                else
                    ignore[1] = "swift"
                end

                if #ignore > 0 then
                    local existing = opts.ignore_install or {}
                    local seen = {}
                    for _, lang in ipairs(existing) do
                        seen[lang] = true
                    end
                    for _, lang in ipairs(ignore) do
                        if not seen[lang] then
                            existing[#existing + 1] = lang
                            seen[lang] = true
                        end
                    end
                    opts.ignore_install = existing
                end
            end
        end
        nvim_treesitter.setup(opts)
    end
}
