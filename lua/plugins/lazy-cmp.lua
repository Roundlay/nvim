return {
    "hrsh7th/nvim-cmp",
    name   = "nvim-cmp",
    enable = true,
    event  = "InsertEnter",
    dependencies = {
        { "L3MON4D3/LuaSnip" }, -- A snippet engine is *required*.
        { "hrsh7th/cmp-nvim-lsp" }, -- Required
        { "hrsh7th/cmp-nvim-lsp-signature-help" },
        { "hrsh7th/cmp-nvim-lua" },
        { "hrsh7th/cmp-path" },
    },
    config = function ()
        local cmp_ok, cmp = pcall(require, "cmp")
        if not cmp_ok then
          return
        end
        cmp.setup({
            preselect = "none",
            completion = {
                completeopt = "menu,menuone,noinsert,noselect" -- 'noselect' avoids inserting text until it is explicitly selected from the completion menu.
            },
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body)
                end
            },
            performance = {
                debounce = 1,
                throttle = 1,
                fetching_timeout = 1,
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
            experimental = {
                ghost_text = false,
            },
            formatting = {
                fields = { "abbr", "menu", "kind" },
                format = function(entry, item)
                    -- Define menu shorthand for different completion sources.
                    local menu_icon = {
                        nvim_lsp = "LSP",
                        nvim_lua = "LUA",
                        luasnip  = "LSN",
                        buffer   = "BUF",
                        path     = "PTH",
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
            view = {
                entries = {
                    name = "custom",
                    -- selection_order = "near_cursor"
                },
            },
            mapping = cmp.mapping.preset.insert({
                ["<CR>"]  = cmp.mapping.confirm({select = false}),
                ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
            }),
            sources = cmp.config.sources({
                { name = "path", options = {}, },
                { name = "nvim_lsp", options = {}, },
                { name = "nvim_lsp_signature_help", },
                { name = "luasnip", options = {}, },
                { name = "nvim_lua", options = {}, },
            }),
        })
    end
}
