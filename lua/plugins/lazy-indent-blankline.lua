-- indent-blankline

return {
    'lukas-reineke/indent-blankline.nvim',
    -- name = "indent-blankline",
    main = "ibl", -- Required after v3.0.0
    enabled = false,
    lazy = true,
    event = {
        "BufReadPost"
    },
    opts = {
        debounce = 1,
        indent = {
            char = "│",
            smart_indent_cap = true,
            highlight = {
                "gates_grey",
            },
            priority = 2,
        },
        scope = {
            enabled = false
        },
        viewport_buffer = {
            min = 100,
            max = 800,
        },
    },
    config = function(_, opts)
        local hooks = require("ibl.hooks")

        -- This changes the indentation line colour to Kanagawa's Winter Blue.
        hooks.register(
            hooks.type.HIGHLIGHT_SETUP, function()
                -- vim.api.nvim_set_hl(0, "winter_blue", { fg = "#252535" }) -- Kanagawa
                vim.api.nvim_set_hl(0, "gates_grey", { fg = "#2d2d2d" })
            end
        )

        -- This changes the indentation character to "┋" when line is empty.
        -- Performance impact unclear, but keep in mind that we're iterating
        -- over all virtual text whenever the cursor moves. This is probably
        -- how earlier versions of the plugin did it anyway.
        -- hooks.register(
        --     hooks.type.VIRTUAL_TEXT, function(_, bufnr, row, virtual_text)
        --         local config = require("ibl.config").get_config(bufnr)
        --         local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
        --         if line == "" then
        --             for _, text in ipairs(virtual_text) do
        --                 if text[1] == config.indent.char then text [1] = "┊"
        --                 -- if text[1] == config.indent.char then text [1] = "╋"
        --                 end
        --             end
        --         end
        --         return virtual_text
        --     end
        -- )

        local ibl_ok, ibl = pcall(require, "ibl")
        if not ibl_ok then
            vim.notify(vim.inspect(ibl), vim.log.levels.ERROR)
            return
        end
        ibl.setup(opts)
    end
}
