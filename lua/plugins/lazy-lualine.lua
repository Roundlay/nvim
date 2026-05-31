local vim = vim

local function truncated_mode(str)
    return str:sub(1, 1)
end

local function compress_directory(dir, separator)
    return dir:sub(1, 1) .. separator
end

local function compress_path(file_path)
    if file_path == "" then
        return ""
    end

    -- Handle Windows drive letter (C:/ or C:\)
    local prefix = file_path:match("^(%a:[/\\])") or ""

    -- Handle Unix absolute path (starts with /)
    if prefix == "" and file_path:sub(1, 1) == "/" then
        -- Replace home directory with ~
        local home = vim.env.HOME
        if home and file_path:sub(1, #home) == home then
            prefix = "~/"
            file_path = file_path:sub(#home + 1)
            -- Strip leading slash after home (now part of prefix)
            if file_path:sub(1, 1) == "/" then
                file_path = file_path:sub(2)
            end
        else
            prefix = "/"
            file_path = file_path:sub(2)
        end
    else
        file_path = file_path:sub(#prefix + 1)
    end

    -- Normalize drive letter to uppercase
    if prefix:match("^%a:") then
        prefix = prefix:gsub("^%a", string.upper)
    end

    -- Split into directories and filename
    local directories, filename = file_path:match("^(.+[/\\])([^/\\]+)$")

    if not filename then
        return prefix .. file_path
    end

    -- Compress each directory to first character
    local compressed = directories:gsub("([^/\\]+)([/\\])", compress_directory)

    return prefix .. compressed .. filename
end

local function truncated_file_status()
    return function()
        local file_path = vim.api.nvim_buf_get_name(0)
        local file_type = vim.bo.filetype

        if file_type == "oil" then
            return "OIL: " .. require("oil").get_current_dir()
        elseif file_type == "term" then
            return "Terminal"
        else
            file_path = compress_path(file_path)

            local state = ""
            if vim.bo.modified then
                state = "MODIFIED"
            elseif vim.bo.readonly then
                state = "READ-ONLY"
            elseif file_path == "" then
                state = "UNNAMED"
            end

            if state ~= "" then
                if file_path ~= "" then
                    return state .. " " .. file_path
                end

                return state
            end

            return file_path
        end
    end
end

-- local function display_tabs()
--     return {
--         'tabs',
--         tab_max_length = 40,
--         max_length = vim.o.columns / 3,
--         mode = 0,
--         path = 0,
--         use_mode_colors = true,
--         show_modified_status = true,
--         symbols = {
--             modified = '+',
--         },
--         fmt = function(name, context)
--             local buflist = vim.fn.tabpagebuflist(context.tabnr)
--             local winnr = vim.fn.tabpagewinnr(context.tabnr)
--             local bufnr = buflist[winnr]
--             local mod = vim.fn.getbufvar(bufnr, '&mod')
--             return name .. (mod == 1 and ' +' or '')
--         end,
--         color = function(context)
--             if context.tabnr == vim.fn.tabpagenr() then
--                 -- Active tab color
--                 return { bg = '#ffffff', fg = '#ffffff' }
--             else
--                 -- Inactive tab color
--                 return { bg = '#ffffff', fg = '#ffffff' }
--             end
--         end
--     }
-- end

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
    lazy = true,
    event = "VimEnter",
    opts = {
        options = {
            always_divide_middle = true,
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            globalstatus = false,
            icons_enabled = false,
            theme = "auto",
            refresh = {
              statusline = 1000,
              tabline = 1000,
              winbar = 1000,
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
            --lualine_x = {display_tabs()},
            lualine_x = {},
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
}
