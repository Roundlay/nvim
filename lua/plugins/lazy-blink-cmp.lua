-- blink.cmp plugin configuration (cleaned line endings)

-- TODO: Set up sources

-- [ ] How can we include any open buffer/window as a source? E.g. docs or help open in split.

return {
    'saghen/blink.cmp',
    enabled = true,
    lazy = true,
    event = 'InsertEnter',
    version = '*',
    opts = {
        keymap = {
            preset = 'default',
            ['<C-\\>'] = {'select_and_accept', 'fallback'},
            ['<C-CR>'] = {'select_and_accept', 'fallback'},
            ['<C-p>']  = {'select_prev',       'fallback'},
            ['<C-n>']  = {'select_next',       'fallback'},
        },
        completion = {
            list = {
                selection = {
                    preselect = false,
                    auto_insert = false,
                },
            },
            trigger = {
                prefetch_on_insert = true,
            },
            menu = {

                -- We should probably just do this in settings: "On neovim 0.11+, you may use the `vim.o.winborder` option to set the default border for all floating windows. You may override that option with your own border value as shown below."

                border = {
                    { "█", "NonText" },
                    { "▀", "NonText" },
                    { "█", "NonText" },
                    { "█", "NonText" },
                    { "█", "NonText" },
                    { "▄", "NonText" },
                    { "█", "NonText" },
                    { "█", "NonText" },
                },
                scrollbar = true,
                draw = {
                    cursorline_priority = 10000,

                    gap      = 1,
                    padding  = { 1, 1 },

                    columns  = {{'label', 'label_description', gap = 1}, {'kind'}},
                    align_to = 'label',

                    components = {
                        kind = {
                            width = { fill = true },
                            ellipsis = true,
                        },

                        label = {
                            width = { fill = true, min = 33, max = 33 },
                        },

                        label_description = {
                            width = { fill = true },
                        },

                        source_name = {
                            width = { fill = true },
                        },

                        source_id = {
                            width = { fill = true },
                        },
                    },
                },
            },

            ghost_text = {
                enabled = false,
            },

            documentation = {
                auto_show = false ,
            },

            keyword = {
                range = 'full',
            },
        },

        signature = {
            window = {
                border = {
                    { "█", "NonText" },
                    { "▀", "NonText" },
                    { "█", "NonText" },
                    { "█", "NonText" },
                    { "█", "NonText" },
                    { "▄", "NonText" },
                    { "█", "NonText" },
                    { "█", "NonText" },
                },
            },
        },

        sources = {
            default = { 'lsp', 'path', 'snippets' },
        },
    },

    opts_extend = { 'sources.default' },

    config = function(_, opts)
        local blink = require("blink.cmp")

        local os_info = vim.uv.os_uname()
        local machine = os_info and os_info.machine or ""
        local is_wsl = vim.fn.has("wsl") == 1
        local is_windows = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1) and not is_wsl

        opts.fuzzy = opts.fuzzy or {}
        if is_windows then
            opts.fuzzy.implementation = "lua"
        else
            opts.fuzzy.implementation = opts.fuzzy.implementation or "prefer_rust_with_warning"
        end

        if is_wsl then
            local triple = nil
            if machine == "x86_64" then
                triple = "x86_64-unknown-linux-gnu"
            elseif machine == "aarch64" then
                triple = "aarch64-unknown-linux-gnu"
            end
            if triple then
                opts.fuzzy.prebuilt_binaries = opts.fuzzy.prebuilt_binaries or {}
                opts.fuzzy.prebuilt_binaries.download = true
                opts.fuzzy.prebuilt_binaries.force_system_triple = triple
            end
        end

        blink.setup(opts)
    end,
}
