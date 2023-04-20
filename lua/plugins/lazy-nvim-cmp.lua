return {
    'hrsh7th/nvim-cmp',
    enabled = true,
    version = false,
    event = "InsertEnter",
    opts = function()
        local cmp = require("cmp")
        return {
            performance = {
                debounce = 0,
                throttle = 0,
                fetching_timeout = 0,
            },
            completion = {
                completeopt = "menu, menuone, noinsert"
            },
            window = {
                completion = {
                    -- winhighlight = "Normal:CmpNormal",
                    scrollbar = false,
                    -- side_padding = 0,
                },
                documentation = {
                    -- winhighlight = "Normal:CmpDocNormal",
                    scrollbar = false,
                    side_padding = 2,
                },
            },
            view = {
                entries = {
                    name = "custom",
                    selection_order = 'near_cursor',
                },
            },
            formatting = {
                fields = {
                    "kind",
                    "abbr"
                },
                format = function(entry, vim_item)
                    vim_item.abbr = " " .. vim_item.abbr
                    vim_item.menu = (vim_item.menu or "") .. " "
                    -- vim_item.kind = cmp_kinds[vim_item.kind]
                    return vim_item
                end,
            },
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body)
                end
            },
            sources = {
                { name = "luasnip", options = {},},
                { name = "path", options = {},},
                { name = "nvim_lsp", options = {},},
            },
            mapping = {
                ["<CR>"]      = cmp.mapping.confirm({select = false}),
                ["<C-n>"]     = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                ["<C-p>"]     = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
                -- ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
                -- ["<C-f>"]     = cmp.mapping.scroll_docs(4),
                -- ["<C-Space>"] = cmp.mapping.complete(),
                -- ["<C-e>"]     = cmp.mapping.abort(),
                -- ["<S-CR>"]    = cmp.mapping.confirm({
                --   behavior    = cmp.ConfirmBehavior.Replace,
                --   select      = true,
                -- }),
                -- ['<C-f>']     = cmp_action.luasnip_jump_forward(),
                -- ['<C-b>']     = cmp_action.luasnip_jump_backward(),
            },
        }
    end,
    config = function(_, opts)
        require('telescope').setup()
    end,
    dependencies = {
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-path',
        'L3MON4D3/LuaSnip',
    },
}
