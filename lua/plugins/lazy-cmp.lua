return {
    "hrsh7th/nvim-cmp",
    enabled = false,
    lazy = true,
    event = "InsertCharPre",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-buffer",
    },
    config = function()
        local cmp_ok, cmp = pcall(require, "cmp")

        if not cmp_ok then
            vim.notify(vim.inspect(cmp), vim.log.levels.ERROR)
            return
        end

        cmp.setup({
            enabled = function()
                local buftype = vim.api.nvim_get_option_value("buftype", {buf = 0})
                local filetype = vim.api.nvim_get_option_value("filetype", {buf = 0})

                if buftype == "prompt" or filetype == "TelescopePrompt" then
                    return false
                end

                return true
            end,
            completion = {
                completeopt = "menu,menuone,noinsert,noselect",
            },

            experimental = {
                ghost_text = false,
                native_menu = false,
            },
            formatting = {
                fields = { "abbr", "kind", "menu" },
                format = function(entry, item)
                    local menu_icon = {
                        nvim_lsp = "LSP",
                        nvim_lua = "LUA",
                    }
                    item.menu = menu_icon[entry.source.name]

                    local content = item.abbr
                    local max_content_width = math.floor(vim.api.nvim_win_get_width(0) * 0.25)

                    if #content > max_content_width then
                        item.abbr = vim.fn.strcharpart(content, 0, max_content_width - 3) .. "..."
                    else
                        item.abbr = content .. (" "):rep(max_content_width - #content)
                    end

                    return item
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ["<CR>"] = cmp.mapping.confirm({ select = false }),
                ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
            }),
            matching = {},
            performance = {
                debounce = 1,
                throttle = 1,
                fetching_timeout = 1,
            },
            preselect = "none",
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body)
                end
            },
            sorting = {
                comparators = {
                    cmp.config.compare.offset,
                    cmp.config.compare.exact,
                    cmp.config.compare.score,
                    function(entry1, entry2)
                        local _, entry1_under = entry1.completion_item.label:find "^_+"
                        local _, entry2_under = entry2.completion_item.label:find "^_+"
                        entry1_under = entry1_under or 0
                        entry2_under = entry2_under or 0
                        if entry1_under > entry2_under then
                            return false
                        elseif entry1_under < entry2_under then
                            return true
                        end
                    end,
                    cmp.config.compare.kind,
                    cmp.config.compare.sort_text,
                    cmp.config.compare.length,
                    cmp.config.compare.order,
                },
            },
            sources = {
                { name = "nvim_lsp" },
                { name = "nvim_lua" },
            },
            view = {
                entries = {
                    name = "custom",
                },
            },
            window = {
                completion = {
                    scrollbar = false,
                },
                documentation = {
                    scrollbar = false,
                    side_padding = 2,
                },
            },
        })
    end
}
