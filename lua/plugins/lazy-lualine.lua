return {
    "nvim-lualine/lualine.nvim",
    name = "lualine",
    enabled = true,
    lazy = false,
    opts = {
        options = {
            always_divide_middle = true,
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            globalstatus = false,
            icons_enabled = false,
            -- theme = "vscode",
            theme = "kanagawa",
        },
        sections = {
            lualine_a = {{ "mode", fmt = function(str) return str:sub(1,1) end }, },
            lualine_b = {{ "diagnostics" }},
            lualine_c = {{ "filename", file_status = true, newfile_status = true, path = 1, shorting_target = 10, symbols = { modified = "MODIFIED", readonly = "READ", unnamed = "UN", newfile = "NF" },},},
            lualine_x = {},
            lualine_y = {{ function() local starts = vim.fn.line("v") local ends = vim.fn.line(".") local count = starts <= ends and ends - starts + 1 or starts - ends + 1 local wc = vim.fn.wordcount() return wc["visual_chars"] end, cond = function() return vim.fn.mode():find("[Vv]") ~= nil end,},},
            lualine_z = {{ "location" }},
       },
    },
    config = function(_, opts)
        require("lualine").setup(opts)
    end,
}
