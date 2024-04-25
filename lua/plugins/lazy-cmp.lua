return {
    "hrsh7th/nvim-cmp",
    -- name = "cmp",
    enable = true,
    lazy = true,
    event = "InsertCharPre",
    dependencies = {
        -- Dependencies without their own setup files and will be automatically
        -- fetched and setup by lazy.nvim, so you don't have to create a setup
        -- file for these.
        -- cmp-nvim-lsp is required for nvim-lspconfig. We call this
        -- within nvim-lspconfig though, so can we just make nvim-lspconfig a
        -- dependency instead? (Seems not...)
        "hrsh7th/cmp-nvim-lsp", -- Required
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
            completion = {
                -- Avoids inserting text until it is explicitly selected from
                -- the completion menu.
                completeopt = "menu,menuone,noinsert,noselect"
            },
            experimental = {
                ghost_text = false,
                native_menu = false,
            },
            formatting = {
                fields = {"abbr", "kind", "menu",},
                format = function(entry, item)
                    -- Define menu shorthand for different completion sources.

                    local menu_icon = {
                        -- luasnip  = "LSN",
                        nvim_lsp = "LSP",
                        nvim_lua = "LUA",
                        buffer = "BUF",
                    }

                    -- Set the menu "icon" to the shorthand for each completion source.
                    item.menu = menu_icon[entry.source.name]

                    -- Set the fixed width of the completion menu to 60 characters in length.
                    -- fixed_width = 20

                    -- Set 'fixed_width' to false if not provided.
                    -- fixed_width = fixed_width or false

                    -- Get the completion entry text shown in the completion window.
                    local content = item.abbr

                    -- Set the fixed completion window width.
                    -- if fixed_width then
                    --     vim.o.pumwidth = fixed_width
                    -- end

                    -- Get the width of the current window.
                    local win_width = vim.api.nvim_win_get_width(0)

                    -- Set the max content width based on either: 'fixed_width' or a percentage of the window width, in this case 20%. We subtract 10 from 'fixed_width' to leave room for the 'kind' and other fields.
                    -- local max_content_width = fixed_width and fixed_width - 10 or math.floor(win_width * 0.2)
                    local max_content_width = math.floor(win_width * 0.25)

                    -- Truncate the completion entry text if it's longer than the max content width. We subtract 3 from the max content width to account for the "..." that will be appended to it.
                    if #content > max_content_width then
                        item.abbr = vim.fn.strcharpart(content, 0, max_content_width - 3) .. "..."
                    else
                        item.abbr = content .. (" "):rep(max_content_width - #content)
                    end

                    return item
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ["<CR>"] = cmp.mapping.confirm({select = false}),
                ["<C-n>"] = cmp.mapping.select_next_item({behavior=cmp.SelectBehavior.Insert}),
                ["<C-p>"] = cmp.mapping.select_prev_item({behavior=cmp.SelectBehavior.Insert}),
            }),
            matching = {
                disallow_fuzzy_matching = false,
                disallow_full_fuzzy_matching = false,
                disallow_partial_fuzzy_matching = false,
                disallow_partial_matching = false,
                disallow_prefix_unmatching = false,
            },
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
                    -- This has the effect of sorting completion items that
                    -- start with an underscore lower than those without. The
                    -- more leading underscores, the lower it will sort.
                    -- https://github.com/pysan3/dotfiles/blob/9d3ca30baecefaa2a6453d8d6d448d62b5614ff2/nvim/lua/plugins/70-nvim-cmp.lua#L39-L49
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
            -- The order of the parameters in sources implicitly controls the
            -- ranking of each source in the completion menu.
            -- sources = cmp.config.sources({
            sources = {
                {name="nvim_lsp", options={},},
                -- {name="nvim_lsp", options={}, entry_filter = function(entry, ctx) return require("cmp").lsp.CompletionItemKind.Text ~= entry:get_kind() end}, -- `entry_filter` filters out completions of kind 'Text'.
                {name="nvim_lua", options={},},
                {name="buffer", options={},},
            },
            -- }),
            view = {
                entries = {
                    name = "custom",
                    -- selection_order = "near_cursor"
                },
            },
            window = {
                completion = {
                    scrollbar = false,
                },
                documentation = {
                    scrollbar = false,
                    side_padding = 2,
                    -- max_height = 40,
                    -- max_width = 80,
                },
            },
        })
    end
}
