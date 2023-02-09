local M = {}

-- -------------------------------------------------------------------------- --
-- Lualine
-- -------------------------------------------------------------------------- --

-- Trigger re-render of status line every second. 
-- -------------------------------------------------------------------------- --

-- function M.rerender_lualine()
--     if _G.Statusline_timer == nil then
--         _G.Statusline_timer = vim.loop.new_timer()
--     else
--         _G.Statusline_timer:stop()
--         vim.api.nvim_command("echo 'Statusline timer stopped.'")
--     end
--     -- `redraws the status line and window bar of the current window, or all
--     -- status lines and window bars if "!" is included.
--     _G.Statusline_timer:start(0, 1000, vim.schedule_wrap(function() vim.api.nvim_command("redrawstatus!") end))
--     vim.api.nvim_command("echo 'Statusline timer started.'")
-- end

-- Get inactive buffer numbers
-- -------------------------------------------------------------------------- --

-- TODO: Find a way to keep track of non-file buffers (autocomplete) and
-- make sure they don't show up in your custom buffer thing.

-- function M.get_inactive_buffer_numbers()
--     inactive_buffer_numbers = {}
--     for i, buffer in ipairs(vim.api.nvim_list_bufs()) do
--         buffer_number = vim.fn.bufnr(buffer)
--         buffer_name = vim.fn.bufname(buffer) 
--         if buffer_number ~= vim.fn.bufnr('%') then
--             if buffer_name:match("^\\[\"#]") or buffer_name:match("^\\[No Name\\]") then
--                 goto continue
--             elseif buffer_name:match("NvimTree_%d") then
--                 table.insert(inactive_buffer_numbers, "꜏")
--             elseif vim.api.nvim_buf_get_var(buffer_number, "changedtick") == vim.fn.changetick() then
--                 table.insert(inactive_buffer_numbers, buffer_number)
--             -- else
--                 -- table.insert(inactive_buffer_numbers, buffer_number)
--             end
--         end
--         ::continue::
--     end
--     inactive_buffer_output = table.concat(inactive_buffer_numbers, ' ')
--     return string.format("%s", inactive_buffer_output)
-- end

-- Get active buffer number
-- -------------------------------------------------------------------------- --

-- function M.get_active_buffer_number()
--     active_buffer = ""
--     for i, buffer in ipairs(vim.api.nvim_list_bufs()) do
--         buffer_number = vim.fn.bufnr(buffer)
--         buffer_name = vim.fn.bufname(buffer)
--         if buffer_number == vim.fn.bufnr('%') then
--             if buffer_name:match("NvimTree_%d") then
--                 active_buffer = "꜏"
--             else
--                 active_buffer = buffer_number
--             end
--             -- active_buffer = buffer_number
--         end
--     end
--     return string.format("%s", active_buffer)
-- end

-- -------------------------------------------------------------------------- --
-- Nvim-tree
-- -------------------------------------------------------------------------- --

-- local old_path = package.path
-- package.path = package.path .. ";<C:/Users/Christopher/.config/nvim/plugs/nvim-tree.lua>/?.lua"
-- package.path = package.path .. ";C:\\Users\\Christopher\\.config\\nvim\\plugs\\nvim-tree.lua\\lua\\nvim-tree\\api.lua"

-- local lib = require('nvim-tree.lib')
-- local view = require('nvim-tree.view')

-- package.path = old_path

-- Open and closes the file tree

-- function M.collapse_all()
--     require("nvim-tree.actions.tree-modifiers.collapse-all").fn()
-- end

-- Open file without closing the tree with 'l'
-- -------------------------------------------------------------------------- --

-- function M.edit_or_open()
--     action = "edit"
--     node = lib.get_node_at_cursor()
--     if node.link_to and not node.nodes then
--         require('nvim-tree.actions.node.open-file').fn(action, node.link_to)
--         view.close() -- Close the tree if file was opened
--     elseif node.nodes ~= nil then
--         lib.expand_or_collapse(node)
--     else
--         require('nvim-tree.actions.node.open-file').fn(action, node.absolute_path)
--         view.close() -- Close the tree if file was opened
--     end
-- end

-- TODO: fix opening and closing with 'L'.
-- 'L' should preview in a split then close again when L is pressed a second time.
-- -------------------------------------------------------------------------- --

-- function M.vsplit_preview()
--     action = "vsplit"
--     node = lib.get_node_at_cursor()
--     if node.link_to and not node.nodes and not vsplitpreview then
--         require('nvim-tree.actions.node.open-file').fn(action, node.link_to)
--         vsplitpreview = true
--     elseif node.nodes ~= nil then
--         lib.expand_or_collapse(node)
--     else
--         require('nvim-tree.actions.node.open-file').fn(action, node.absolute_path)
--     end
--     view.focus()
-- end

return M
