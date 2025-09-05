-- blink.cmp plugin configuration (cleaned line endings)

-- TODO: Set up sources

-- [ ] How can we include any open buffer/window as a source? E.g. docs or help open in split.

return {
    'saghen/blink.cmp',

    enabled = true,
    lazy = true,
    event = 'InsertCharPre',
    version = '*',
    opts = {
        keymap = {
            preset = 'default',
            ['<C-\\>'] = {'select_and_accept', 'fallback'},
            ['<C-CR>'] = {'select_and_accept', 'fallback'},
            ['<C-p>'] = {'select_prev', 'fallback'},
            ['<C-n>'] = {'select_next', 'fallback'},
        },
        completion = {
            list = {
                selection = {
                    preselect = false,
                    auto_insert = false,
                },
            },
            menu = {
                scrollbar = true,
                draw = {
                    columns = { { 'label', 'label_description', gap = 1 }, { 'kind' } },
                    align_to = 'label',
                    padding = { 1, 1 },
                    gap = 1,
                    cursorline_priority = 10000,
                    components = {
                        kind = {
                            width = { fill = true },
                            ellipsis = true,
                            text = function(ctx)
                                return ctx.kind
                            end,
                            highlight = function(ctx)
                                return ctx.kind_hl
                            end,
                        },

                        label = {
                            width = { fill = true, min = 33, max = 33 },
                            text = function(ctx)
                                return ctx.label .. ctx.label_detail
                            end,
                        },

                        label_description = {
                            width = { fill = true },
                            text = function(ctx)
                                return ctx.label_description
                            end,
                            highlight = 'BlinkCmpLabelDescription',
                        },

                        source_name = {
                            width = { fill = true },
                            text = function(ctx)
                                return ctx.source_name
                            end,
                            highlight = 'BlinkCmpSource',
                        },

                        source_id = {
                            width = { fill = true },
                            text = function(ctx)
                                return ctx.source_id
                            end,
                            highlight = 'BlinkCmpSource',
                        },
                    },
                },
            },
            ghost_text = {
                enabled = false,
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 0,
                draw = function(opts) opts.default_implementation() end,
                window = {
                    min_width = 40,
                    max_width = 40,
                    -- max_height = 15,
                    scrollbar = true,
                },
            },
            keyword = {
                range = 'full',
            },
        },
        sources = {
            default = { 'lsp', 'path', 'snippets' },
        },
    },
    opts_extend = { 'sources.default' },
    config = function(_, opts)
        local blink_ok, blink = pcall(require, 'blink-cmp')
        if not blink_ok then
            vim.notify(vim.inspect(blink), vim.log.levels.ERROR)
            return
        end
        blink.setup(opts)
    end,
}
