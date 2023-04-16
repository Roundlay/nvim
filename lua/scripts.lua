-- scripts.lua

local M = {}

-- ========================================================================== --
-- Keybinding Helpers
-- ========================================================================== --

-- function M.Map(mode, new, old, opts)
--     -- map("n", ";f", ":Telescope find_files<CR>", {expr = true})
--     local default_opts = {}
--     if opts then
--         options = vim.tbl_extend("force", default_opts, opts) -- Merges the `default_opts` and `opts` tables
--     end
--     vim.api.nvim_set_keymap(mode, new, old, options)
-- end

-- function M.Insert(new, old)
--     vim.api.nvim_set_keymap('i', new, old, {noremap=true, silent=true})
-- end

-- function M.Normal(new, old)
--     vim.api.nvim_set_keymap('n', new, old, {noremap=true, silent=true})
-- end

-- function M.Visual(new, old)
--     vim.api.nvim_set_keymap('v', new, old, {noremap=true, silent=true})
-- end

-- function M.Terminal(new, old)
--     vim.api.nvim_set_keymap('t', new, old, {buffer = 0})
-- end

-- ========================================================================== --
-- Language Helpers
-- ========================================================================== --

-- Odin
-- -------------------------------------------------------------------------- --

-- Run `orf $file` from within Neovim and display the output in a split window.

-- function orf()
--     local output = vim.fn.systemlist('orf ' .. vim.fn.expand('%'))
--     local bufnr = vim.api.nvim_create_buf(false, true)
--     vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
--     vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
--     vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
--     vim.api.nvim_buf_set_option(bufnr, 'filetype', 'odin')
--     vim.api.nvim_buf_set_option(bufnr, 'syntax', 'odin')
--     vim.api.nvim_buf_set_option(bufnr, 'modifiable', false) -- Make buffer read-only
--     -- vim.cmd('vnew')
--     vim.cmd('split')
--     vim.api.nvim_win_set_buf(0, bufnr)
--     vim.api.nvim_win_set_option(0, 'wrap', false)
--     vim.api.nvim_win_set_height(0, 10)
--     vim.cmd('normal! gg')
--     vim.cmd('redraw')
-- end

-- This is an experiment in creating a code compilation watch window in Lua for Neovim.

-- function bsop(buffer, name, value)
--     vim.api.nvim_buf_set_option(buffer, name, value)
-- end
--
-- local bufnr = nil
-- function on_save()
--     local filepath = vim.fn.expand('%:p:h')
--     local tempdir = filepath .. '/temp'
--     if not vim.fn.isdirectory(tempdir) then
--         os.execute("mkdir " .. tempdir)
--         -- vim.fn.mkdir(tempdir)
--     end
--     local timestamp = os.time(os.date("!*t"))
--     local tempname = tempdir .. '/' .. vim.fn.expand('%:t:r') .. '_temp_' .. timestamp .. '.odin'
--     vim.api.nvim_command('silent w! ' .. tempname)
--     local output = vim.fn.systemlist('odin run ' .. tempname .. ' -file')
--     if not bufnr then
--         bufnr = vim.api.nvim_create_buf(false, true)
--         vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
--         vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
--         vim.api.nvim_buf_set_option(bufnr, 'filetype', 'odin')
--         vim.api.nvim_buf_set_option(bufnr, 'syntax', 'odin')
--         vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
--         vim.cmd('split')
--         local winid = vim.fn.win_getid()
--         vim.api.nvim_win_set_buf(winid,bufnr)
--         vim.api.nvim_win_set_option(winid,'wrap',true)
--         vim.api.nvim_win_set_height(winid,10)
--     end
--     local current_win = vim.fn.win_getid()
--     local winids = vim.fn.win_findbuf(bufnr) 
--     for _, winid in ipairs(winids) do 
--         if winid ~= current_win then 
--             pcall(vim.api.nvim_buf_set_option,bufnr,'modifiable',true) 
--             pcall(vim.api.nvim_win_call,
--             winid,
--             function()
--                 pcall(vim.api.nvim_buf_set_lines,bufnr,0,-1,false,output) 
--             end) 
--             pcall(vim.api.nvim_buf_set_option,bufnr,'modifiable',false)  
--         end  
--     end  
-- end
-- function odin_live()
--     vim.cmd('autocmd BufWritePost <buffer> lua on_save()') 
-- end

-- local bufnr = nil
-- function on_save()
--     -- Create temporary file with same content as current buffer
--     local filepath = vim.fn.expand('%:p:h')
--     local tempdir = filepath .. '/temp'
--     if not vim.fn.isdirectory(tempdir) then
--         vim.fn.mkdir(tempdir)
--     end
--     local tempname = tempdir .. '/' .. vim.fn.expand('%:t') .. '.tmp'
--     vim.api.nvim_command('silent w! ' .. tempname)
--     
--     -- Run odin command on temporary file
--     local output = vim.fn.systemlist('odin run ' .. tempname .. ' -file')
--     
--     if not bufnr then
--         bufnr = vim.api.nvim_create_buf(false, true)
--         vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
--         vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
--         vim.api.nvim_buf_set_option(bufnr, 'filetype', 'odin')
--         vim.api.nvim_buf_set_option(bufnr, 'syntax', 'odin')
--         -- Make buffer read-only
--         vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
--         -- Open new split window and display buffer
--         -- vim.cmd('vnew')
--         vim.cmd('split')
--         local winid = vim.fn.win_getid()
--         vim.api.nvim_win_set_buf(winid,bufnr)
--         -- Set wrap property to true
--         vim.api.nvim_win_set_option(winid,'wrap',true)
--         -- Set window height to 10 lines
--         vim.api.nvim_win_set_height(winid,10)
--     end
--     
--     -- Update buffer content in background without taking control away from cursor in main buffer 
--     local current_win = vim.fn.win_getid()
--     local winids = vim.fn.win_findbuf(bufnr) 
--     for _, winid in ipairs(winids) do 
--       if winid ~= current_win then 
--           -- Temporarily set modifiable to true to update buffer content 
--           pcall(vim.api.nvim_buf_set_option,bufnr,'modifiable',true) 
--           -- Update buffer content without moving cursor from main window 
--           pcall(vim.api.nvim_win_call,
--             winid,
--             function()
--               pcall(vim.api.nvim_buf_set_lines,bufnr,0,-1,false,output) 
--             end) 
--           -- Set modifiable back to false after updating content  
--           pcall(vim.api.nvim_buf_set_option,bufnr,'modifiable',false)  
--       end  
--     end  
-- end

-- function odin_live()
--   -- Register autocommand to run on_save function when the current buffer is written 
--   vim.cmd('autocmd BufWritePost <buffer> lua on_save()') 
-- end

-- This is a temporary function for calling `ebert.bat` on the Eebs folder for ebook testing.

-- local M = {}
-- function M.Ebert()
--     local folder_name = vim.fn.input('Enter folder name: ')
--     if folder_name ~= '' then
--         local folder_path = "C:\\Users\\Christopher\\Projects\\Eebs\\" .. folder_name
--         local output = vim.fn.system('ebert.bat "' .. folder_path .. '"')
--         print(output)
--     end
-- end

-- ========================================================================== --
-- Misc.
-- ========================================================================== --

-- Get the Golden Ratio of the current window by passing in width or height
-- -------------------------------------------------------------------------- --

function M.Golden(dimension)
  local win_height = vim.api.nvim_win_get_height(0)
  local win_width = vim.api.nvim_win_get_width(0)
  local golden_ratio = (1 + math.sqrt(5)) / 2
  local value
  if dimension == "height" then
    value = math.floor(win_width / golden_ratio)
  elseif dimension == "width" then
    value = math.floor(win_height * golden_ratio)
  else
    error("Invalid dimension. Must be 'height' or 'width'")
  end
  if value > win_height and dimension == "height" then
    value = win_height
  elseif value > win_width and dimension == "width" then
    value = win_width
  end
  return value
end

-- Reload Lua Packages
-- ------------------------------------------------------------------------- --

-- TODO
-- function _G.ReloadConfig()
--     for name, _ in pairs(package.loaded) do
--         -- If the name of the module starts with 'lua' then remove the module
--         -- from the package.loaded table
--         -- TODO: Not sure this'll work for lua folder itself.
--         if name:match('^lua') then
--             package.loaded[name] = nil
--         end
--     end
--     dofile(vim.env.MYVIMRC)
-- end

-- ========================================================================== --
-- Plugins
-- ========================================================================== --

-- -------------------------------------------------------------------------- --
-- Lualine
-- -------------------------------------------------------------------------- --

-- Trigger re-render of status line every second. 
-- -------------------------------------------------------------------------- --

function M.rerender_lualine()
    if _G.Statusline_timer == nil then
        _G.Statusline_timer = vim.loop.new_timer()
    else
        _G.Statusline_timer:stop()
        vim.api.nvim_command("echo 'Statusline timer stopped.'")
    end
    -- Redraws *all* statuslines and window bars if "!" is included after `redrawstatus`.
    _G.Statusline_timer:start(0, 1000, vim.schedule_wrap(function() vim.api.nvim_command("redrawstatus!") end))
    vim.api.nvim_command("echo 'Statusline timer started.'")
end

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
-- -------------------------------------------------------------------------- --

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
