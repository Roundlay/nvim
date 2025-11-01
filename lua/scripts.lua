-- scripts.lua
if vim.g.vscode then
    return
end

-- Module boiler-plate

---@type table<string,any>
local M = _G.M or {}
_G.M = M  -- expose for other modules/old code paths

-------------------------------------------------------------------------------

-- C Return Type Helper (now in lua/scripts/c_return_types.lua)
local function get_c_return_module()
    local ok, mod = pcall(require, "scripts.c_return_types")
    if not ok then
        return nil
    end
    return mod
end

function M:show_c_return_types()
    local mod = get_c_return_module()
    if not mod then
        return
    end
    if mod.setup then
        mod.setup()
    end
    if mod.show then
        mod.show()
    end
end

M:show_c_return_types()

-- -----------------------------------------------------------------------------

-- Custom Diagnostics Formatting & Highlighting
local function get_custom_diagnostics_module()
    local ok, mod = pcall(require, "scripts.custom_diagnostics")
    if not ok then
        return nil
    end
    return mod
end

function M:custom_diagnostics_formatter()
    local mod = get_custom_diagnostics_module()
    if not mod then
        return
    end
    if mod.setup then
        mod.setup()
    end
end

M:custom_diagnostics_formatter()

-------------------------------------------------------------------------------
-- Custom Numberline

-- [ ] TODO Doesn't work in help files. Is that because they're READ-ONLY?
-- [ ] TODO Add support for plugin style setup functions within package
-- managers, e.g. Lazy. I.e. refactor this as a plugin.
    -- [ ] Check Lazy documentation and other plugins.
    -- [ ] Add support for toggleable options like colours, highlighting the
    -- active line in the numberline, padding, etc.

function M:pretty_line_numbers()
    require("scripts.pretty_line_numbers").setup()
end

-- -------------------------------------------------------------------------- --

-- WRAPPIN'

local function get_wrappin_module()
    local ok, mod = pcall(require, "scripts.wrappin")
    if not ok then
        return nil
    end
    return mod
end

local function run_wrappin(...)
    local mod = get_wrappin_module()
    if not mod or type(mod.run) ~= "function" then
        return
    end
    return mod.run(...)
end

function M:wrappin(...)
    return run_wrappin(...)
end

-- TAG WRAPPER

local function get_wrap_with_tags_module()
    local ok, mod = pcall(require, "scripts.wrap_with_tags")
    if not ok then
        return nil
    end
    return mod
end

local function run_wrap_with_tags(...)
    local mod = get_wrap_with_tags_module()
    if not mod or type(mod.run) ~= "function" then
        return
    end
    return mod.run(...)
end

function M:wrap_with_tags(...)
    return run_wrap_with_tags(...)
end

-- -------------------------------------------------------------------------- --

-- VISREP

local function get_visrep_module()
    local ok, mod = pcall(require, "scripts.visrep")
    if not ok then
        return nil
    end
    return mod
end

local function run_visrep(...)
    local mod = get_visrep_module()
    if not mod or type(mod.run) ~= "function" then
        return
    end
    return mod.run(...)
end

function M:visrep(...)
    return run_visrep(...)
end

--------------------------------------------------------------------------------
-- Slect 0.1.0
--------------------------------------------------------------------------------

-- Draw virtual text over selected text or at the cursor position.

-- local ns_id = vim.api.nvim_create_namespace("SlectNamespace")
--
-- _G.Slect = function()
--   print("Slect called")
--
--   local bufnr = vim.api.nvim_get_current_buf()
--   local cursor_pos = vim.api.nvim_win_get_cursor(0)
--   local line, col = cursor_pos[1] - 1, cursor_pos[2]
--   local virtual_text = ""
--   local extmark_id
--
--   local function update_virtual_text(text)
--     print("Updating virtual text")
--     vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
--     extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, col, {
--       virt_text = {{text, "Comment"}},
--       virt_text_win_col = col,
--       hl_mode = "combine",
--     })
--     vim.api.nvim_win_set_cursor(0, cursor_pos)
--     vim.api.nvim_command("redraw")
--   end
--
--   while true do
--     local key = vim.fn.getchar()
--     local c = vim.fn.nr2char(key)
--     print("Key pressed: " .. c)
--
--     if c == "\r" then
--       vim.api.nvim_buf_del_extmark(bufnr, ns_id, extmark_id)
--       break
--     elseif c == "\27" then  -- Esc key
--       update_virtual_text("")
--       vim.api.nvim_buf_del_extmark(bufnr, ns_id, extmark_id)
--       break
--     else
--       virtual_text = virtual_text .. c
--       update_virtual_text(virtual_text)
--     end
--   end
-- end

--------------------------------------------------------------------------------
-- SLECT 0.2.0
--------------------------------------------------------------------------------

-- The idea here was to play around with idea for a Neovim paintbrush. I.e. Move
-- a virtual cursor around the screen and add text to the buffer.

-- local api = vim.api
-- local ns_id = api.nvim_create_namespace('Slect')
--
-- local function validate_cursor(buf, cursor)
--     local line_count = api.nvim_buf_line_count(buf)
--     local max_col = api.nvim_buf_get_lines(buf, cursor[1], cursor[1]+1, false)[1]:len()
--     cursor[1] = math.max(0, math.min(line_count - 1, cursor[1]))
--     cursor[2] = math.max(0, math.min(max_col, cursor[2]))
--     return cursor
-- end
--
-- local function update_virtual_text(buf, virtual_cursor, vcursor_id)
--     -- Update the extmark to the new position
--     print("Updating text:", virtual_cursor, vcursor_id)
--     api.nvim_buf_set_extmark(buf, ns_id, virtual_cursor[1], virtual_cursor[2], {
--         virt_text = {{"|", "Comment"}},
--         -- Make it right-aligned so it behaves more like a cursor
--         virt_text_pos = "overlay",
--         id = vcursor_id
--     })
-- end
--
-- _G.Slect = function()
--     local buf = api.nvim_get_current_buf()
--     print("Buffer:", buf)
--     local win = api.nvim_get_current_win()
--
--     local cursor = api.nvim_win_get_cursor(win)
--     local virtual_cursor = {cursor[1] - 1, cursor[2]} -- 0-based indexing
--
--     -- Set the initial virtual cursor and save its ID
--     local vcursor_id = api.nvim_buf_set_extmark(buf, ns_id, virtual_cursor[1], virtual_cursor[2], {
--         virt_text = {{"x", "Search"}},
--         -- Make it right-aligned so it behaves more like a cursor
--         virt_text_pos = "overlay",
--     })
--
--     local function on_input(key)
--         virtual_cursor = validate_cursor(buf, virtual_cursor)
--         if key == 'j' then
--             virtual_cursor[1] = virtual_cursor[1] + 1
--         elseif key == 'k' then
--             virtual_cursor[1] = virtual_cursor[1] - 1
--         elseif key == 'h' then
--             virtual_cursor[2] = virtual_cursor[2] - 1
--         elseif key == 'l' then
--             virtual_cursor[2] = virtual_cursor[2] + 1
--         else
--             return true
--         end
--         -- Update the virtual cursor's position
--         update_virtual_text(buf, virtual_cursor, vcursor_id)
--         vim.cmd("redraw")
--         return false
--     end
--     local success = vim.fn.input({prompt = '', func = 'v:lua.Slect_on_input', cancelreturn = ''})
--     api.nvim_buf_del_extmark(buf, ns_id, vcursor_id)
--     api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
-- end
--
-- function _G.Slect_on_input(key)
--   return on_input(key)
-- end

--------------------------------------------------------------------------------
-- Odin Compiler Helpers
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- MISC.
--------------------------------------------------------------------------------

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Golden Ration Helper for Window Sizing
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Get the Golden Ratio of the current window by passing in width or height
-- function M.PrintWidth()
--     local width = math.floor(vim.api.nvim_win_get_width(0) / ((1 + math.sqrt(5)) / 2 * 100))
--     local height = math.floor(vim.api.nvim_win_get_height(0) / ((1 + math.sqrt(5)) / 2 * 100))
--     return width, height
-- end

-- M.Width = math.floor(vim.api.nvim_win_get_width(0) / ((1 + math.sqrt(5)) / 2 * 100))
-- M.Height = math.floor(vim.api.nvim_win_get_height(0) / ((1 + math.sqrt(5)) / 2 * 100))

-- function M.Golden(dimension)
--   local win_height = vim.api.nvim_win_get_height(0)
--   local win_width = vim.api.nvim_win_get_width(0)
--   local golden_ratio = (1 + math.sqrt(5)) / 2
--   local value
--   if dimension == "height" then
--     value = math.floor(win_width / golden_ratio)
--   elseif dimension == "width" then
--     value = math.floor(win_height * golden_ratio)
--   else
--     error("Invalid dimension. Must be 'height' or 'width'")
--   end
--   if value > win_height and dimension == "height" then
--     value = win_height
--   elseif value > win_width and dimension == "width" then
--     value = win_width
--   end
--   return value
-- end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Reload Lua Packages
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- TODO: Does this do anything?
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

--------------------------------------------------------------------------------
-- Plugins
--------------------------------------------------------------------------------

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Source Plugins
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- TODO: Does this work?

-- local installed_plugins = {
--     -- ["lukas-reineke/indent-blankline.nvim"] = "lukas-reineke/indent-blankline.nvim",
--     -- ["lukas-reineke/indent-blankline.nvim"] = "indent-blankline",
-- }
--
-- local function case_insensitive_compare(str1, str2)
--     return str1:lower() == str2:lower()
-- end
--
-- function M.PopulateInstalledPlugins()
--     local plug_dirs = vim.fn.globpath("C:/Users/Christopher/.config/nvim/plugs", "*", true, true)
--     for _, dir in ipairs(plug_dirs) do
--         local plugin_name = vim.fn.fnamemodify(dir, ":t")
--         installed_plugins[plugin_name] = dir
--     end
-- end
--
-- function M.PrintInstalledPlugins()
--     for plugin_name, plugin_path in pairs(installed_plugins) do
--         print(plugin_name .. " => " .. plugin_path)
--     end
-- end
--
-- function M.SourcePlugin(plugin_name)
--     plugin_name = plugin_name:gsub("^%s*(.-)%s*$", "%1") -- Trim leading/trailing spaces
--     for installed_plugin_name, plugin_path in pairs(installed_plugins) do
--         if case_insensitive_compare(installed_plugin_name, plugin_name) then
--             local sourced = pcall(dofile, plugin_path)
--             if sourced then
--                 print("Sourced " .. plugin_name)
--             else
--                 print("Failed to source " .. plugin_name)
--             end
--             return
--         end
--     end
--     print(plugin_name .. " not found.")
-- end
--
-- function M.PromptAndSourcePlugin()
--     local plugin_name = vim.fn.input("input", "Enter plugin name: ")
--     SourcePlugin(plugin_name)
-- end
--
-- function M.SetPluginSourcingKeybinding()
--     vim.api.nvim_set_keymap("n", "<leader>z", ":SourcePlugin<CR>", {noremap = true, silent = false})
-- end
--
-- vim.cmd("command! SourcePlugin lua PromptAndSourcePlugin()")

-- Call this in init.lua or plugins.lua.
-- PopulateInstalledPlugins()

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- AccelerateJK Acceleration/Deceleration Heuristics
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- I think this was something to do with the accelerate_jk plugin.

-- function M.generate_series(type, n, factor)
--     local series = {}
--     if type == "quadratic" then
--         for i = 1, n do
--             table.insert(series, i * i * factor)
--         end
--     elseif type == "cubic" then
--         for i = 1, n do
--             table.insert(series, i * i * i * factor)
--         end
--     end
--     return series
-- end
--
-- local acceleration_table = M.generate_series("quadratic", 4, 5)
-- local deceleration_table = {}
--
-- local deceleration_intervals = {200, 300}
-- for _, interval in ipairs(deceleration_intervals) do
--     local deceleration_steps = M.generate_series("quadratic", 2, 3)
--     table.insert(deceleration_table, {interval, deceleration_steps})
-- end
--
-- print("Acceleration Table: ")
-- for _, value in ipairs(acceleration_table) do
--     print(value)
-- end
--
-- print("\nDeceleration Table: ")
-- for _, pair in ipairs(deceleration_table) do
--     print(pair[1], table.concat(pair[2], ", "))
-- end

-- Is this here for a reason?
-- Picture in Picture plugin?
-- [ ] Could this be pegged to a certain part of the file even while scrolling?
-- [ ] Could this be used to do the one line scrolling thing?
-- M.Border = vim.api.nvim_open_win(0, true, {relative='win', width=vim.api.nvim_win_get_width(0), height=3, bufpos=vim.api.nvim_win_get_cursor(), border = "none" })
-- vim.api.nvim_open_win(0, true, {relative='win', width=vim.api.nvim_win_get_width(0), height=3, bufpos=vim.api.nvim_win_get_cursor(), border = "none" })

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Lualine
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Trigger re-render of status line every second.
-- NOTE: Was this related to including a clock in the statusline
-- function M.rerender_lualine()
--     if _G.Statusline_timer == nil then
--         _G.Statusline_timer = vim.loop.new_timer()
--     else
--         _G.Statusline_timer:stop()
--         vim.api.nvim_command("echo 'Statusline timer stopped.'")
--     end
--     -- Redraws *all* statuslines and window bars if "!" is included after `redrawstatus`.
--     _G.Statusline_timer:start(0, 1000, vim.schedule_wrap(function() vim.api.nvim_command("redrawstatus!") end))
--     vim.api.nvim_command("echo 'Statusline timer started.'")
-- end

-- Get inactive buffer numbers
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

-- Key testing function to diagnose terminal key sequences
-- function _G.TestKey()
--     print("Press a key combination (or 'q' to quit):")
--     local key = vim.fn.getchar()
--     if type(key) == "number" then
--         local char = vim.fn.nr2char(key)
--         print(string.format("Received: char='%s', code=%d (0x%X)", char, key, key))
--     else
--         print(string.format("Received: %s", vim.inspect(key)))
--     end
--     if key ~= 113 then -- 'q' = 113
--         _G.TestKey()
--     end
-- end

return M
