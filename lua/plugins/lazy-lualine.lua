return {
    "nvim-lualine/lualine.nvim",
    name = "lualine",
    enabled = true,
    lazy = false,
    opts = {
        options = {
            always_divide_middle = true,
            component_separators = { left = '', right = '' },
            section_separators = { left = '', right = '' },
            globalstatus = false,
            icons_enabled = false,
            theme = 'kanagawa',
        },
        sections = {
            lualine_a = {{'mode', fmt = function(str) return str:sub(1,1) end}}, -- Display the mode as a single character.
            lualine_b = {{'diagnostics'}},
            lualine_c = {{'filename', file_status = true, newfile_status = true, path = 1, shorting_target = 10, symbols = {modified = '♯', readonly = 'RO', unnamed = 'UN', newfile = 'NF'}}},
            lualine_x = {},
            lualine_y = {},
            -- lualine_y = {{require("lazy.status").updates, cond = require("lazy.status").has_updates, color = { fg = "ff9e64" }}},
            -- lualine_y = {{"os.date('%I:%M %p')"}}, -- Doesn't update consistently.
            lualine_z = {{'location'}},
       },
    },
    config = function(_, opts)
        require("lualine").setup(opts)
    end,
}
