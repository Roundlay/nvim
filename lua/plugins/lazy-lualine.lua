local function truncated_mode(str)
    return str:sub(1, 1)
end

local function truncated_file_status()
    return function()
        local file_path = vim.api.nvim_buf_get_name(0)
        local filetype = vim.bo.filetype

        if filetype == "oil" then
            return "OIL: " .. require("oil").get_current_dir()
        elseif filetype == "term" then
            return "Terminal"
        else
            -- Compress filepath logic
            local drive = file_path:match("^(%a:\\)") or ""
            local path_without_drive = file_path:sub(#drive + 1, -1)
            local directories, filename = path_without_drive:match("^(.+\\)([^\\]+)$")

            directories = directories or ""

            local compressed_directories = directories:gsub("([^\\]+\\)", function(dir)
                return dir:sub(1, 1) .. "\\"
            end)

            file_path = drive .. compressed_directories .. filename

            local state = ""
            if vim.bo.modified then
                state = "MODIFIED"
            elseif vim.bo.readonly then
                state = "READ"
            elseif file_path == "" then
                state = "UNNAMED"
            end

            return state == "" and file_path or state .. " " .. file_path
        end
    end
end

local function display_tabs()
    return {
        'tabs',
        tab_max_length = 40,
        max_length = vim.o.columns / 3,
        mode = 0,
        path = 0,
        use_mode_colors = true,
        show_modified_status = true,
        symbols = {
            modified = '+',
        },
        fmt = function(name, context)
            local buflist = vim.fn.tabpagebuflist(context.tabnr)
            local winnr = vim.fn.tabpagewinnr(context.tabnr)
            local bufnr = buflist[winnr]
            local mod = vim.fn.getbufvar(bufnr, '&mod')
            return name .. (mod == 1 and ' +' or '')
        end,
        color = function(context)
            if context.tabnr == vim.fn.tabpagenr() then
                -- Active tab color
                return { bg = '#ffffff', fg = '#ffffff' }
            else
                -- Inactive tab color
                return { bg = '#ffffff', fg = '#ffffff' }
            end
        end
    }
end

local function visual_selection_count()
    return {
        function()
            local wc = vim.fn.wordcount()
            return wc["visual_chars"]
        end,
        cond = function()
            return vim.fn.mode():find("[Vv]") ~= nil
        end,
    }
end

return {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    lazy = true,
    event = "VimEnter",
    opts = {
        options = {
            always_divide_middle = true,
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            globalstatus = false,
            icons_enabled = false,
            theme = "vscode",
            -- theme = "kanagawa",
            refresh = {
              statusline = 1,  -- Note these are in mili second and default is 1000
              tabline = 1,
              winbar = 1,
            }
        },
        extension = {
            "mason",
            "lazy",
            "lualine",
            "oil",
        },
        sections = {
            lualine_a = {{"mode", fmt = truncated_mode}},
            lualine_b = {{truncated_file_status()}},
            lualine_c = {},
            lualine_x = {display_tabs() },
            lualine_y = {visual_selection_count()},
            lualine_z = {{"location"}},
        },
        inactive_sections = {
            lualine_a = {{truncated_file_status()}},
            lualine_b = {},
            lualine_c = {},
            lualine_x = {},
            lualine_y = {},
            lualine_z = {},
        },
    },
    config = function(_, opts)
        local lualine_ok, lualine = pcall(require, "lualine")
        if not lualine_ok then
            vim.notify(vim.inspect(lualine), vim.log.levels.ERROR)
            return
        end
        lualine.setup(opts)
    end,
}
