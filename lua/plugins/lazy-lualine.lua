return {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    lazy = false,
    config = function()
        require("lualine").setup({
            options = {
                always_divide_middle = true,
                component_separators = { left = '', right = '' },
                section_separators = { left = '', right = '' },
                globalstatus = false,
                icons_enabled = false,
                theme = 'kanagawa',
            }, 
            sections = {
                lualine_a = {{'mode', fmt = function(str) return str:sub(1,1) end}},
                -- lualine_a = {{'mode', show_modified_status = true, mode = 2},},
                lualine_b = {{'diagnostics'}},
                -- lualine_b = {'diff', 'diagnostics'},
                lualine_c = {{'filename', file_status = true, newfile_status = true, path = 1, shorting_target = 10, symbols = {modified = 'MO', readonly = 'RO', unnamed = 'UN', newfile = 'NF'}}},
                lualine_x = {{require("lazy.status").updates, cond = require("lazy.status").has_updates, color = {fg = "#FF9E64"},}},
                -- lualine_x = {{'buffers', mode = 1, show_modified_status = false, max_length = 3, padding = {left = 1, right = 0} },},
                -- lualine_x = {{active_buffer_number, color = {fg = '#7E9CD8'}}, {inactive_buffer_numbers, color = {fg = '#717C7C'}, padding = {left = 0, right = 1}}},
                lualine_y = {{'progress'}},
                -- lualine_y = {{'fileformat', symbols = {unix = 'UNIX', dos = 'DOS', mac = 'Mac', odin = 'ODIN', lua = 'LUA'}}, 'filetype'},
                -- lualine_y = {{"os.date('%I:%M:%S %p')"}}, -- Need to uncomment render update time block below for seconds to update properly
                lualine_z = {{'location'}},
            },
        })
    end,
    init = function()
        if _G.Statusline_timer == nil then
            _G.Statusline_timer = vim.loop.new_timer()
        else
            _G.Statusline_timer:stop()
        end
        _G.Statusline_timer:start(0, 1000, vim.schedule_wrap(
        function() vim.api.nvim_command('redrawstatus') end))
        local function inactive_buffer_numbers()
            local inactive_buffer_numbers = {}
            for i, buffer in ipairs(vim.api.nvim_list_bufs()) do
                local buffer_number = vim.fn.bufnr(buffer)
                local buffer_name = vim.fn.bufname(buffer) 
                if buffer_number ~= vim.fn.bufnr('%') then
                    if buffer_name:match("NvimTree_1") then
                        table.insert(inactive_buffer_numbers, "꜏")
                    else
                        table.insert(inactive_buffer_numbers, buffer_number)
                    end
                end
            end
            local inactive_buffer_output = table.concat(inactive_buffer_numbers, ' ')
            return string.format("%s", inactive_buffer_output)
        end
        local function active_buffer_number()
            local active_buffer = ""
            for i, buffer in ipairs(vim.api.nvim_list_bufs()) do
                local buffer_number = vim.fn.bufnr(buffer)
                local buffer_name = vim.fn.bufname(buffer)
                if buffer_number == vim.fn.bufnr('%') then
                    if buffer_name:match("NvimTree_%d") then
                        active_buffer = "꜏"
                    else
                        active_buffer = buffer_number
                    end
                    -- active_buffer = buffer_number
                end
            end
            return string.format("%s", active_buffer)
        end
        local nvimtree_buffer_name = {symbols = {modified = 'MO', readonly = 'RO', unnamed = 'UN', newfile = 'NF'}}
        vim.cmd [[ au BufEnter,BufWinEnter,WinEnter,CmdwinEnter * if bufname('%') == "NvimTree_1" | set bufname('%') == '' | endif ]]
    end,
}
