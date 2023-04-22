return {
    "hrsh7th/nvim-cmp",
    name = "nvim-cmp",
    enable = true,
    event = "InsertEnter",
    dependencies = {
        { "hrsh7th/cmp-nvim-lsp" },
        { "hrsh7th/cmp-nvim-lsp-signature-help" },
        { "hrsh7th/cmp-path" },
        { "L3MON4D3/LuaSnip"},
    },
    config = function ()

        -- Completion engine 
        local cmp_ok, cmp = pcall(require, "cmp")
        if not cmp_ok then
          return
        end

        -- Snippet engine
        local luasnip_ok, luasnip = pcall(require, "luasnip")
        if not luasnip_ok then
          return
        end

        -- Setup function
        cmp.setup({
            completion = {
                -- See: `:help completeopt`.
                -- `noselect` avoids inserting text until it is explicitly selected from the completion menu.
                completeopt = "menu, preview, menuone, noinsert, noselect"
            },
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body)
                end
            },
            performance = {
                debounce = 0,
                throttle = 0,
                fetching_timeout = 0,
            },
            window = {
                completion = {
                    scrollbar = false
                },
                documentation = {
                    scrollbar = false,
                    side_padding = 2,
                    max_height = 80,
                },
            },
            formatting = {
                fields = { "abbr", "menu", "kind" },
                format = function(entry, item)
                    local menu_icon = {
                        nvim_lsp = "λ",
                        luasnip = "⋗",
                        buffer = "Ω",
                        path = "🖫",
                        nvim_lua = "Π",
                    }
                    item.menu = menu_icon[entry.source.name]
                    return item
                end,
            },
            view = {
                entries = {
                    name = "custom",
                    selection_order = "near_cursor"
                },
            },
            mapping = cmp.mapping.preset.insert({
                ["<CR>"]  = cmp.mapping.confirm({select = false}),
                ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
            }),
            preselect = {
                cmp.PreselectMode.None,
            },
            sources = cmp.config.sources({
                { name = "path", options = {}, priority = 100 },
                { name = "nvim_lsp", options = {}, priority = 100 },
                { name = "nvim_lsp_signature_help", priority = 80 },
                { name = "luasnip", options = {}, priority = 20 },
            })
        })
    end
}
