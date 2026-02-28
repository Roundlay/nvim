-- indent-blankline

return {
    'lukas-reineke/indent-blankline.nvim',
    main = "ibl", -- Required after v3.0.0
    enabled = false,
    lazy = true,
    event = "BufReadPost",
    opts = {
        debounce = 0.1,
        indent = {
            char = "│",
            smart_indent_cap = true,
            -- highlight = {
            --     "gates_grey",
            -- },
            priority = 2,
        },
        scope = {
            enabled = false,
        },
        viewport_buffer = {
            min = 100,
            max = 800,
        },
    },
}
