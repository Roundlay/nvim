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
            theme = "kanagawa",
        },
        extension = {
            "mason",
            "lazy",
            "lualine",
            "oil",
        },
        sections = {
            lualine_a = {
                {"mode", fmt = function(str) return str:sub(1, 1) end},
            },
            -- lualine_b = {
            --     {"filename", file_status = true, newfile_status = true, path = 1, shorting_target = 10, symbols = { modified = "MODIFIED", readonly = "READ", unnamed = "UN", newfile = "NF" },},
            -- },
            lualine_b = {
                {
                    function()
                        local file_path = vim.api.nvim_buf_get_name(0)
                        local filetype = vim.bo.filetype

                        if filetype == "oil" then
                            file_path = "CWD: " .. require("oil").get_current_dir()
                        else
                            if filetype == "term" then
                                file_path = "Terminal"
                            else
                                -- if filetype ~= "oil" then
                                -- This compresses the buffer's filepath, excluding the drive alias and the filename.
                                local drive = file_path:match("^(%a:\\)") or ""
                                local path_without_drive = file_path:sub(#drive + 1, -1)
                                local directories, filename = path_without_drive:match("^(.+\\)([^\\]+)$")

                                directories = directories or ""

                                local compressed_directories = directories:gsub("([^\\]+\\)", function(dir)
                                    -- Keep first character of each directory and add backslash
                                    return dir:sub(1, 1) .. "\\"
                                end)

                                file_path = drive .. compressed_directories .. filename
                            end

                            local state = ""
                            if vim.bo.modified then
                                state = "MODIFIED"
                            elseif vim.bo.readonly then
                                state = "READ"
                            elseif file_path == "" then
                                state = "UNNAMED"
                            end

                            if state == "" then
                                return file_path
                            else
                                return state .. " " .. file_path
                            end
                        end
                    end,
                },
            },
            lualine_c = {},
            lualine_x = {
                {
                    'tabs',
                    tab_max_length = 40,  -- Maximum width of each tab. The content will be shorten dynamically (example: apple/orange -> a/orange)
                    max_length = vim.o.columns / 3, -- Maximum width of tabs component.
                    mode = 0, -- 0: Shows tab_nr
                    path = 0, -- 0: just shows the filename
                    use_mode_colors = false,
                    show_modified_status = true,  -- Shows a symbol next to the tab name if the file has been modified.
                    symbols = {
                        modified = '[+]',  -- Text to show when the file is modified.
                    },
                    fmt = function(name, context)
                        -- Show + if buffer is modified in tab
                        local buflist = vim.fn.tabpagebuflist(context.tabnr)
                        local winnr = vim.fn.tabpagewinnr(context.tabnr)
                        local bufnr = buflist[winnr]
                        local mod = vim.fn.getbufvar(bufnr, '&mod')
                        return name .. (mod == 1 and ' +' or '')
                    end
                }
            },
            -- lualine_x = {
            --     {
            --         function()
            --             local hl_enabled = vim.v.hlsearch == 1
            --             local result = vim.fn.searchcount({recompute = 1, maxcount = 1000})
            --             local output = '[0/0]'
            --
            --             if result.total > 0 then
            --                 if result.incomplete == 1 then
            --                     output = string.format('[?/%d+]', result.total)
            --                 elseif result.incomplete == 2 then
            --                     output = string.format('[%d/1000+]', result.current)
            --                 else
            --                     output = string.format('[%d/%d]', result.current, result.total)
            --                 end
            --             end
            --
            --             if not hl_enabled then
            --                 -- Apply dim color style
            --                 output = '%#SearchCounterDim#' .. output
            --             end
            --
            --             return output
            --         end
            --     }
            -- },
            -- lualine_y = {{function() local starts = vim.fn.line("v") local ends = vim.fn.line(".") local count = starts <= ends and ends - starts + 1 or starts - ends + 1 local wc = vim.fn.wordcount() return wc["visual_chars"] end, cond = function() return vim.fn.mode():find("[Vv]") ~= nil end,}},
            lualine_y = {
                {
                    function()
                        local starts = vim.fn.line("v")
                        local ends = vim.fn.line(".")
                        local count = starts <= ends and ends - starts + 1 or starts - ends + 1
                        local wc = vim.fn.wordcount()
                        return wc["visual_chars"]
                    end,
                    cond = function()
                        return vim.fn.mode():find("[Vv]") ~= nil
                    end,
                }
            },
            lualine_z = { { "location" } },
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
