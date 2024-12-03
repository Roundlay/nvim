-- scripts.lua

if vim.g.vscode then
    return
end

M = {}

-- -------------------------------------------------------------------------- --

-- DIAGNOSTICS/ERROR RENDERER

function M:setup_diagnostics()
    -- Namespace for diagnostic extmarks
    local ns = vim.api.nvim_create_namespace("custom_diagnostics")
    local diagnostic_extmark_start_id = 10000
    local max_diagnostics_per_line = 5 -- Configure maximum diagnostics per line

    -- Function to check if the current buffer is "nofile"
    local function is_nofile_buffer(bufnr)
        return vim.bo[bufnr].buftype == "nofile"
    end

    -- Function to calculate gutter width
    local function get_gutter_width()
        local has_numbers = vim.wo.number or vim.wo.relativenumber
        if not has_numbers then
            return 0
        end
        return vim.wo.numberwidth
    end

    -- Define the virtual text highlight to use both foreground and background
    -- color
    vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = 0xf00823, bg = 0x360714 })

    -- Function to wrap text to fit within the window width
    local function wrap_text(text, width)
        local wrapped_lines = {}
        local current_line = ""

        for word in text:gmatch("%S+") do
            if #current_line + #word + 1 <= width then
                current_line = current_line == "" and word or current_line .. " " .. word
            else
                table.insert(wrapped_lines, current_line)
                current_line = word
            end
        end

        -- Insert the last line
        if current_line ~= "" then
            table.insert(wrapped_lines, current_line)
        end

        return wrapped_lines
    end

    -- Function to render diagnostics above offending lines with padding and
    -- matching indentation
    function M.render_diagnostics(bufnr, diagnostics)
        if is_nofile_buffer(bufnr) then
            return
        end

        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

        if #diagnostics == 0 then
            return
        end

        local win_width = vim.api.nvim_win_get_width(0)
        local gutter_width = get_gutter_width()
        local line_count = vim.api.nvim_buf_line_count(bufnr)

        local line_stacks = {}
        for _, diagnostic in ipairs(diagnostics) do
            if diagnostic.lnum < line_count then
                if not line_stacks[diagnostic.lnum] then
                    line_stacks[diagnostic.lnum] = {}
                end
                table.insert(line_stacks[diagnostic.lnum], diagnostic)
            end
        end

        local extmark_id = diagnostic_extmark_start_id
        for lnum, diags in pairs(line_stacks) do
            local virt_lines = {}
            local indent_level = vim.fn.indent(lnum + 1)
            -- Determine if we need to limit diagnostics for this line
            local total_diagnostics = #diags
            local diagnostics_to_show = diags
            if total_diagnostics > max_diagnostics_per_line then
                -- Take only the first max_diagnostics_per_line diagnostics
                diagnostics_to_show = {}
                for i = 1, max_diagnostics_per_line do
                    diagnostics_to_show[i] = diags[i]
                end
            end

            -- Process the diagnostics we're going to show
            for _, diagnostic in ipairs(diagnostics_to_show) do
                local max_len = win_width - gutter_width - 6
                local wrapped_msg = wrap_text(diagnostic.message:gsub("\n", " "), max_len)

                for _, msg_line in ipairs(wrapped_msg) do
                    local total_width = win_width - gutter_width
                    local prefixed_msg = string.rep(" ", indent_level) .. msg_line
                    local remaining_space = total_width - #prefixed_msg
                    local full_line = prefixed_msg .. string.rep(" ", remaining_space)
                    table.insert(virt_lines, {{ full_line, "DiagnosticVirtualTextError" }})
                end
            end

            -- Add the summary line if we limited diagnostics
            if total_diagnostics > max_diagnostics_per_line then
                local remaining = total_diagnostics - max_diagnostics_per_line
                local summary_msg = string.format("...and %d more diagnostic%s on this line",
                    remaining,
                    remaining > 1 and "s" or ""
                )
                local total_width = win_width - gutter_width
                local prefixed_msg = string.rep(" ", indent_level) .. summary_msg
                local remaining_space = total_width - #prefixed_msg
                local full_line = prefixed_msg .. string.rep(" ", remaining_space)
                table.insert(virt_lines, {{ full_line, "DiagnosticVirtualTextError" }})
            end

            if lnum < line_count then
                vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
                    virt_lines = virt_lines,
                    virt_lines_above = true,
                    priority = 200,
                    id = extmark_id,
                })
                extmark_id = extmark_id + 1
            end
        end
    end

    -- Function to highlight offending lines (full background)
    function M.highlight_error_lines(bufnr, diagnostics)
        if is_nofile_buffer(bufnr) then
            return
        end

        local line_count = vim.api.nvim_buf_line_count(bufnr)
        for _, diagnostic in ipairs(diagnostics) do
            if diagnostic.lnum < line_count then
                vim.api.nvim_buf_add_highlight(bufnr, ns, "DiagnosticLineError", diagnostic.lnum, 0, -1)
            end
        end
    end

    -- Create a debounced refresh function to prevent excessive updates
    local refresh_timer = nil
    local function refresh_diagnostics()
        if refresh_timer then
            vim.fn.timer_stop(refresh_timer)
        end
        refresh_timer = vim.fn.timer_start(10, function()
            if is_nofile_buffer(0) then
                return
            end
            local diagnostics = vim.diagnostic.get(0)
            M.render_diagnostics(0, diagnostics)
            M.highlight_error_lines(0, diagnostics)
            refresh_timer = nil
        end)
    end

    -- Set up autocommands with immediate response for option changes
    local option_group = vim.api.nvim_create_augroup("DiagnosticUpdates", { clear = true })
    -- Watch for number and relativenumber changes specifically
    vim.api.nvim_create_autocmd("OptionSet", {
        pattern = {"number", "relativenumber", "numberwidth"},
        group = option_group,
        callback = function()
            vim.schedule(refresh_diagnostics)
        end,
    })

    -- Watch for window/buffer changes
    vim.api.nvim_create_autocmd(
        {"CursorMoved", "TextChanged", "InsertLeave", "VimResized", "WinScrolled"},
        {
            group = option_group,
            buffer = 0,
            callback = refresh_diagnostics,
        }
    )

    -- Configure custom diagnostic handlers
    vim.diagnostic.handlers.custom = {
        show = function(namespace, bufnr, diagnostics)
            if is_nofile_buffer(bufnr) then
                return
            end
            M.render_diagnostics(bufnr, diagnostics)
            M.highlight_error_lines(bufnr, diagnostics)
        end,
        hide = function(namespace, bufnr)
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        end,
    }

    -- Disable default virtual text diagnostics
    vim.diagnostic.config({
        virtual_text = false,
    })
end

M:setup_diagnostics()

-----

-- NUMBERLINE RENDERER

-- Buggy.

-- BUG: The active buffer determins the number of characters in the numberline 
-- BUG: When swapping to a buffer with C-w, the newly active buffer's numberline gains extra buffer columns equal to the width of the numberline columns in the buffer with the largest number of numberline columns. The extra padding columns, and the extra prefix characters, disappears after entering Insert mode. E.g. Buffer 1 has 678 rows, Buffer 2 has 25, and Buffer 3 has 339. When the active buffer is Buffer 2, all other buffers have a numberline with width 2 (a huge issue when the other buffers have hundreds or thousands of lines). When the active buffer is Buffer 3, all buffers have a numberline with width 3 (even Buffer 2, which has 25 lines. This causes the padding column to the right of the numberline to shrink and expand based on the active buffer.
-- [X] Check if this has something to do with any of the buffers being in READONLY mode.
    -- Doesn't
-- [X] Check if this has something to do with conflicting plugins that affect the numberline. E.g. Focus.
    -- Doesn't

function _G.format_line_number()
  local lnum, rnum, virtnum = vim.v.lnum, vim.v.relnum, vim.v.virtnum

  -- If the current line is virtual (i.e., it's part of virtual diagnostics or wrapped text), skip displaying the line number
  if virtnum ~= 0 then
    return string.rep(" ", #tostring(vim.fn.line("$"))) -- Return blank space for virtual lines
  end

  local total_lines = vim.fn.line("$")
  local max_width = #tostring(total_lines)

  -- Check if this is a wrapped line
  if virtnum > 0 then
    -- Determine if this wrapped line is part of the active line
    local is_active_wrapped = (rnum == 0)
    local dot_hl = is_active_wrapped and "CursorLineNr" or "LineNr"
    -- Return dots for wrapped lines with appropriate highlight
    return string.format("%%#%s#%s %%*", dot_hl, string.rep("·", max_width))
  end

  local number_to_display
  local is_active_line = (rnum == 0)
  if vim.wo.relativenumber then
    number_to_display = is_active_line and lnum or math.abs(rnum)
  else
    number_to_display = lnum
  end

  -- Convert number to string and pad with zeros
  local num_str = string.format("%0" .. max_width .. "d", number_to_display)

  -- Always split into prefix and actual number, even for special windows
  local prefix = string.match(num_str, "^0+") or ""
  local actual_num = string.sub(num_str, #prefix + 1)

  -- Determine highlight groups
  local prefix_hl = "LineNrPrefix"
  local number_hl = is_active_line and "CursorLineNr" or "LineNr"

  -- Construct the formatted string with different highlights
  local result = string.format("%%#%s#%s%%#%s#%s %%*",
                               prefix_hl, prefix,
                               number_hl, actual_num)

  return result
end

-- Set the statuscolumn option to use the new formatter
-- This enables the custom numberline.
-- vim.opt.statuscolumn = "%!v:lua.format_line_number()"

-- -------------------------------------------------------------------------- --

-- WOAH THERE, COWBOY

function M.cowboy()
	---@type table?
	local id
	local ok = true
	for _, key in ipairs({ "h", "j", "k", "l", "+", "-" }) do
		local count = 0
		local timer = assert(vim.loop.new_timer())
		local map = key
		vim.keymap.set("n", key, function()
			if vim.v.count > 0 then
				count = 0
			end
			if count >= 10 then
				ok, id = pcall(vim.notify, "Hold it Cowboy!", vim.log.levels.WARN, {
					icon = ">:(",
					replace = id,
					keep = function()
						return count >= 10
					end,
				})
				if not ok then
					id = nil
					return map
				end
			else
				count = count + 1
				timer:start(2000, 0, function()
					count = 0
				end)
				return map
			end
		end, { expr = true, silent = true })
	end
end

-- -------------------------------------------------------------------------- --

-- RELOAD SCRIPTS

-- _G.ReloadScripts = function()
--     local initial_state = package.loaded['scripts']
--     if package.loaded['scripts'] then
--         package.loaded['scripts'] = nil
--         if package.loaded['scripts'] ~= initial_state then
--             require('scripts')
--             if package.loaded['scripts'] == initial_state then
--                 vim.notify(os.date("[%H:%M:%S] ").."Scripts module reloaded successfully.", vim.log.levels.INFO)
--             end
--         end
--     end
-- end

-- -------------------------------------------------------------------------- --

-- SHOW REGION MARKS AND LINES (?)

_G.show_region_marks_and_lines = function()
    local buffer = 0
    local start_table  = vim.api.nvim_buf_get_mark(buffer, '<')
    local start_line   = start_table[1] - 1
    local start_column = start_table[2]
    local end_table    = vim.api.nvim_buf_get_mark(buffer, '>')
    local end_line     = end_table[1]
    local end_column   = end_table[2]
    local range_table  = vim.api.nvim_buf_get_lines(buffer, start_line, end_line, true)
    -- If start_col > 0 or end_col < 100000, then it's a per character
    -- (character-wise) visual mode selection/range.
    -- So, adjust the first and last line.
    -- I do not know how to find out if it's a block-wise (rectangular) selection.
    if start_column > 0 then
        range_table[1] = string.sub(range_table[1], start_column + 1)
    end
    if end_column < 100000 then
        range_table[#range_table] = string.sub(range_table[#range_table], 1, end_column)
    end
end

-- -------------------------------------------------------------------------- --

-- WRAPPIN'

-- Reversably soft wrap lines that are longer than n characters at the nth
-- column. The default wrap column is column 80. The script respects comment
-- prefixes and inline comments. It also respects the initial indentation of the
-- first line in the selection.

-- TODO: We should add support for rewrapping multiple lines, where one or more
-- of the lines are already wrapped. E.g. if we have a selection of 4 lines,
-- where lines 1, 2, and 4 are already within the wrap boundary, but 3 has a
-- length longer than our wrap column, we should be able to reflow everything
-- below the offending line.

_G.Wrappin = function()
    local start_line = vim.fn.getpos("'<")[2] - 1
    local end_line = vim.fn.getpos("'>")[2] - 1
    local max_width = 80

    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line+1, false)
    if #lines == 0 then return end
    -- Analyze first line for comment pattern
    local initial_indent = lines[1]:match("^(%s*)")
    local comment_prefix = lines[1]:match("^%s*([%-/]+%s*)") or ""
    -- Detect if we're in wrapped state (B) or single-line state (A)
    local is_wrapped = #lines > 1 and lines[2]:match("^%s*" .. vim.pesc(comment_prefix))
    if is_wrapped then
        -- UNWRAP: Join lines, removing duplicate comment prefixes
        local content = {}
        for _, line in ipairs(lines) do
            local cleaned = line:gsub("^%s*" .. vim.pesc(comment_prefix), "", 1)
            table.insert(content, cleaned)
        end
        local single_line = initial_indent .. comment_prefix ..
                           table.concat(content, " "):gsub("%s+", " ")
        vim.api.nvim_buf_set_lines(0, start_line, end_line+1, false, {single_line})
    else
        -- WRAP: Split into multiple lines with comment prefix
        local content = lines[1]
        local words = {}
        -- If this is already a comment line, don't look for inline comments
        if content:match("^%s*[%-/]+%s+") then
            content = content:gsub("^%s*" .. vim.pesc(comment_prefix), "")
            for word in content:gmatch("%S+") do
                table.insert(words, word)
            end
        else
            -- Only look for inline comments in non-comment lines
            content = content:gsub("^%s*" .. vim.pesc(comment_prefix), "")
            local code_part, comment_part = content:match("^(.-)%s*(//.*)$")
            if code_part and comment_part then
                -- Process code part
                for word in code_part:gmatch("%S+") do
                    table.insert(words, word)
                end
                -- Add comment as a single unit
                table.insert(words, comment_part)
            else
                -- No inline comment, process normally
                for word in content:gmatch("%S+") do
                    table.insert(words, word)
                end
            end
        end
        local new_lines = {}
        local current_line = initial_indent .. comment_prefix
        local line_width = #current_line
        for i, word in ipairs(words) do
            local space_needed = i > 1 and 1 or 0
            local word_width = #word + space_needed
            -- Special handling for comments, but only if we're not already in a comment
            local is_comment = not content:match("^%s*[%-/]+%s+") and word:match("^//")
            if is_comment then
                -- If current line plus comment would exceed width, wrap first
                if line_width > #initial_indent then
                    table.insert(new_lines, current_line)
                    current_line = initial_indent
                    line_width = #current_line
                end
                -- Add comment as a single unit
                current_line = current_line .. word
                line_width = #current_line
            else
                -- Normal word handling
                if line_width + word_width > max_width then
                    table.insert(new_lines, current_line)
                    current_line = initial_indent .. comment_prefix .. word
                    line_width = #current_line
                else
                    current_line = current_line .. (space_needed > 0 and " " or "") .. word
                    line_width = line_width + word_width
                end
            end
        end
        if current_line ~= "" then
            table.insert(new_lines, current_line)
        end
        vim.api.nvim_buf_set_lines(0, start_line, end_line+1, false, new_lines)
    end
end

-- -------------------------------------------------------------------------- --

-- VISREP

-- Replace visually selected text globally with a new string. Respects word
-- boundaries.

_G.Visrep = function()
    local cursor_pos = vim.fn.getpos('.')

    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local selected_text = vim.fn.getline(start_pos[2], end_pos[2])
    local pattern = ''

    -- Concatenate all selected lines into a single pattern
    for i, line in ipairs(selected_text) do
        if i > 1 then pattern = pattern .. '\n' end
        local start_col = 1
        local end_col = #line
        if i == 1 then
            start_col = start_pos[3]
        end
        if i == #selected_text then
            end_col = end_pos[3]
        end
        pattern = pattern .. line:sub(start_col, end_col)
    end

    local new_string = vim.fn.input('Replace "' .. pattern .. '" with: ')
    if new_string ~= "" then
        -- Pick a separator that is not in pattern or new_string
        local separators = { '/', '#', '%', '!', '@', '$', '^', '&', '*', '+', '=', '?', '|', '~' }
        local sep = nil
        for _, s in ipairs(separators) do
            if not pattern:find(s, 1, true) and not new_string:find(s, 1, true) then
                sep = s
                break
            end
        end
        if not sep then
            print("Could not find a suitable separator for the pattern and replacement.")
            return
        end

        local regex_specials = '().%+-*?[]^$\\|/'
        local escaped_pattern = vim.fn.escape(pattern, sep .. '\\' .. regex_specials)
        local escaped_new_string = vim.fn.escape(new_string, sep .. '\\')

        local final_pattern = '\\v(\\k)@<!' .. escaped_pattern .. '(\\k)@!'

        vim.cmd(':%s' .. sep .. final_pattern .. sep .. escaped_new_string .. sep .. 'g')
    end

    vim.fn.setpos('.', cursor_pos)
end

-- -----------------------------------------------------------------------------

-- Slect 0.1.0
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

-- Slect 0.2.0
-- Move a virtual cursor around the screen and add text to the buffer.
-- -----------------------------------------------------------------------------

local api = vim.api
local ns_id = api.nvim_create_namespace('Slect')

local function validate_cursor(buf, cursor)
    local line_count = api.nvim_buf_line_count(buf)
    local max_col = api.nvim_buf_get_lines(buf, cursor[1], cursor[1]+1, false)[1]:len()
    cursor[1] = math.max(0, math.min(line_count - 1, cursor[1]))
    cursor[2] = math.max(0, math.min(max_col, cursor[2]))
    return cursor
end

local function update_virtual_text(buf, virtual_cursor, vcursor_id)
    -- Update the extmark to the new position
    print("Updating text:", virtual_cursor, vcursor_id) 
    api.nvim_buf_set_extmark(buf, ns_id, virtual_cursor[1], virtual_cursor[2], {
        virt_text = {{"|", "Comment"}},
        -- Make it right-aligned so it behaves more like a cursor
        virt_text_pos = "overlay",
        id = vcursor_id
    })
end

_G.Slect = function()

    local buf = api.nvim_get_current_buf()
    print("Buffer:", buf)
    local win = api.nvim_get_current_win()

    local cursor = api.nvim_win_get_cursor(win)
    local virtual_cursor = {cursor[1] - 1, cursor[2]} -- 0-based indexing

    -- Set the initial virtual cursor and save its ID
    local vcursor_id = api.nvim_buf_set_extmark(buf, ns_id, virtual_cursor[1], virtual_cursor[2], {
        virt_text = {{"x", "Search"}},
        -- Make it right-aligned so it behaves more like a cursor
        virt_text_pos = "overlay",
    })

    local function on_input(key)
        virtual_cursor = validate_cursor(buf, virtual_cursor)
        if key == 'j' then
            virtual_cursor[1] = virtual_cursor[1] + 1
        elseif key == 'k' then
            virtual_cursor[1] = virtual_cursor[1] - 1
        elseif key == 'h' then
            virtual_cursor[2] = virtual_cursor[2] - 1
        elseif key == 'l' then
            virtual_cursor[2] = virtual_cursor[2] + 1
        else
            return true
        end
        -- Update the virtual cursor's position
        update_virtual_text(buf, virtual_cursor, vcursor_id)
        vim.cmd("redraw")
        return false
    end
    local success = vim.fn.input({prompt = '', func = 'v:lua.Slect_on_input', cancelreturn = ''})
    api.nvim_buf_del_extmark(buf, ns_id, vcursor_id)
    api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
end

function _G.Slect_on_input(key)
  return on_input(key)
end

--------------------------------------------------------------------------------

-- Function to auto-close HTML tags
-- Doesn't work.
-- _G.auto_close_tags = function()
--     local bufnr = vim.api.nvim_get_current_buf()
--     local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
--     
--     for i, line in ipairs(lines) do
--         -- This simple pattern matches tags that might require self-closing
--         -- Note: Lua patterns do not support lookbehind; thus, the solution is basic
--         local modifiedLine = line:gsub("(<(%w+)[^>/]*)>", function(tagStart)
--             local voidElements = "area|base|br|col|command|embed|hr|img|input|keygen|link|meta|param|source|track|wbr"
--             if tagStart:match(voidElements) then
--                 return tagStart .. " />"
--             else
--                 return tagStart .. ">"
--             end
--         end)
--
--         if modifiedLine ~= line then
--             vim.api.nvim_buf_set_lines(bufnr, i-1, i, false, {modifiedLine})
--         end
--     end
-- end

-- DO NOT EDIT: 

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

-- Picture in Picture plugin?
-- [ ] Could this be pegged to a certain part of the file even while scrolling?
-- [ ] Could this be used to do the one line scrolling thing?
-- M.Border = vim.api.nvim_open_win(0, true, {relative='win', width=vim.api.nvim_win_get_width(0), height=3, bufpos=vim.api.nvim_win_get_cursor(), border = "none" })
-- vim.api.nvim_open_win(0, true, {relative='win', width=vim.api.nvim_win_get_width(0), height=3, bufpos=vim.api.nvim_win_get_cursor(), border = "none" })

-- ========================================================================== --
-- Source Plugins
-- ========================================================================== --

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
