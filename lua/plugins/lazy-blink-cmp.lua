-- blink.cmp

-- TODO: Set up sources

-- [ ] How can we include any open buffer/window as a source? E.g. docs or help open in split.

return {
    'saghen/blink.cmp',
    
    enabled = true,
    lazy = true,
    event = "InsertCharPre",
    version = '*',
    opts = {
        keymap = {
            preset = "default",
            ["<C-\\>"] = { "select_and_accept", "fallback" },
            ["<C-CR>"] = { "select_and_accept", "fallback" },
            ["<C-p>"] = { "select_prev", "fallback" },
            ["<C-n>"] = { "select_next", "fallback" },
        },
        appearance = {
            -- use_nvim_cmp_as_default = true,
            -- nerd_font_variant = 'mono',
        },
        completion = {
            list = {
                selection = {
                    preselect = false,
                    auto_insert = false,
                },
            },
            menu = {
                -- Restrict the floating completion window to exactly 40 columns.  In
                -- Blink v0.7.0+ the size of the popup can be controlled through the
                -- `win_config` table which is forwarded to `nvim_open_win`.  Setting
                -- both the minimum and maximum width guarantees that the menu never
                -- grows beyond ‑ or shrinks below ‑ 40 characters.
                win_config = {
                    max_width = 40,
                    min_width = 40,
                },
                scrollbar = true,
                draw = {
                    columns = {{"label", "label_description", gap = 1}, {"kind"}},
                    align_to = "label",
                    padding = {1, 1},
                    gap = 1,
                    cursorline_priority = 10000,
                    treesitter = {},
                    components = {
                        kind = {
                          ellipsis = false,
                          width = { fill = true },
                          text = function(ctx) return ctx.kind end,
                          highlight = function(ctx) return ctx.kind_hl end,
                        },

                        label = {
                            width = { fill = true, max = 60 },
                            text = function(ctx) return ctx.label .. ctx.label_detail end,
                        },

                        label_description = {
                            width = { max = 30 },
                            text = function(ctx) return ctx.label_description end,
                            highlight = 'BlinkCmpLabelDescription',
                        },

                        source_name = {
                          width = { max = 30 },
                          text = function(ctx) return ctx.source_name end,
                          highlight = 'BlinkCmpSource',
                        },
                    
                        source_id = {
                          width = { max = 30 },
                          text = function(ctx) return ctx.source_id end,
                          highlight = 'BlinkCmpSource',
                        },
                    },
                },
            },

            ghost_text = {
                enabled = false,
            },
            documentation = {
                auto_show = false,
                auto_show_delay_ms = 333,
            },
            keyword = {
                range = "full",
            },
        },
        sources = {
            default = { 'lsp', 'path', 'snippets', },
        },
    },

    opts_extend = { "sources.default" },

    config = function(_, opts)
        local blink_ok, blink = pcall(require, "blink-cmp")
        if not blink_ok then
            vim.notify(vim.inspect(blink), vim.log.levels.ERROR)
            return
        end
        blink.setup(opts)
    end,
}
