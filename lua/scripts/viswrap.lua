if vim.g.vscode then
    return
end

local M = {}

-- VISWRAP
-- Wrap visually selected text globally with a pair of fences.
-- Respects word boundaries, or not.

local function run()
    -- Ensure we exit visual mode to update the '< and '> marks
    local cur_mode = vim.api.nvim_get_mode().mode
    if cur_mode == 'v' or cur_mode == 'V' or cur_mode == '\22' then -- \22 is CTRL-V
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)
    end

    local cursor_pos = vim.fn.getpos('.')
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    
    print("VisWrap Debug: Mode="..cur_mode.." Start="..vim.inspect(start_pos).." End="..vim.inspect(end_pos))

    -- Validation: Ensure marks are valid and something is selected
    if start_pos[2] == 0 or end_pos[2] == 0 then
        print("VisWrap: No selection found (marks invalid).")
        return
    end

    local selected_text = vim.fn.getline(start_pos[2], end_pos[2])
    local pattern = ''
    
    -- Concatenate selected lines into a single string
    if type(selected_text) == 'string' then selected_text = { selected_text } end -- Handle single line edge case
    for i, line in ipairs(selected_text) do
        if i > 1 then
            pattern = pattern .. '\n'
        end
        local start_col = (i == 1) and start_pos[3] or 1
        local end_col = (i == #selected_text) and end_pos[3] or #line
        pattern = pattern .. line:sub(start_col, end_col)
    end

    if pattern == '' then
        print("VisWrap: Selection empty.")
        return
    end

    local is_single_line = not pattern:find('\n', 1, true)
    -- Default to boundary mode only if it looks like a standard keyword.
    local defaults_to_boundary = is_single_line and (pattern:match('^[%w_]+$') ~= nil)
    
    -- Build literal core as sequence of byte matches for robustness.
    local core = {}
    for i = 1, #pattern do
        core[#core+1] = string.format('\\%%x%02X', pattern:byte(i))
    end
    local literal_core = table.concat(core)
    
    local pattern_any   = '\\V' .. literal_core
    
    -- Construct boundary pattern manually.
    local pattern_word = nil
    if is_single_line then
        local b_char = '[^0-9A-Za-z_]'
        pattern_word = '\\m\\%(' .. '^\\|' .. b_char .. '\\)\\@<=' .. literal_core .. '\\%(' .. '$\\|' .. b_char .. '\\)\\@='
    end
    
    local mode = (defaults_to_boundary and 'boundary') or 'anywhere'
    
    local function is_word_char_byte(b)
        if not b then return false end
        return (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b == 95) or (b >= 97 and b <= 122)
    end
    
    local function push_merged(list, col0, col1)
        local n = #list
        if n == 0 or col0 > list[n].col1 then
            list[n + 1] = { col0 = col0, col1 = col1 }
        else
            if col1 > list[n].col1 then list[n].col1 = col1 end
        end
    end
    
    local function build_match_index(bufnr, literal, sel_lnum, sel_col0, sel_col1)
        local lc = vim.api.nvim_buf_line_count(bufnr)
        local by_any = {}
        local by_bnd = {}
        local nav_any = {}
        local nav_bnd = {}
        if #literal > 0 then
            for lnum = 0, lc - 1 do
                local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ''
                local init = 1
                local list_any = nil
                local list_bnd = nil
                while true do
                    local s, e = string.find(line, literal, init, true)
                    if not s then break end
                    local c0, c1 = s - 1, e
                    -- anywhere list
                    list_any = list_any or {}
                    push_merged(list_any, c0, c1)
                    nav_any[#nav_any + 1] = { lnum = lnum, col0 = c0, col1 = c1 }
                    -- boundary list
                    local prev = (s > 1) and string.byte(line, s - 1) or nil
                    local nextb = (e < #line) and string.byte(line, e + 1) or nil
                    if not is_word_char_byte(prev) and not is_word_char_byte(nextb) then
                        list_bnd = list_bnd or {}
                        push_merged(list_bnd, c0, c1)
                        nav_bnd[#nav_bnd + 1] = { lnum = lnum, col0 = c0, col1 = c1 }
                    end
                    init = e + 1
                end
                if list_any then by_any[lnum] = list_any end
                if list_bnd then by_bnd[lnum] = list_bnd end
            end
        end
        -- ensure selection present
        local function ensure(listmap, navlist)
            local exists = false
            local t = listmap[sel_lnum]
            if t then
                for _, iv in ipairs(t) do
                    if iv.col0 == sel_col0 and iv.col1 == sel_col1 then exists = true; break end
                end
            end
            if not exists then
                if not t then t = {}; listmap[sel_lnum] = t end
                push_merged(t, sel_col0, sel_col1)
                navlist[#navlist + 1] = { lnum = sel_lnum, col0 = sel_col0, col1 = sel_col1 }
            end
        end
        ensure(by_any, nav_any)
        ensure(by_bnd, nav_bnd)
        return by_any, by_bnd, nav_any, nav_bnd
    end
    
    local ns = vim.api.nvim_create_namespace('VisWrapPreview')
    local function clear_ns(bufnr)
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
    
    pcall(vim.api.nvim_set_hl, 0, 'VisWrapFence',  { link = 'IncSearch' })
    
    local bufnr = vim.api.nvim_get_current_buf()
    local literal = pattern
    local cur_idx = nil
    
    -- Initial Build Index
    -- If multiline, we skip global search and just target selection
    local by_line_any, by_line_bnd, nav_any, nav_bnd
    if is_single_line then
        by_line_any, by_line_bnd, nav_any, nav_bnd = build_match_index(bufnr, literal, start_pos[2]-1, start_pos[3]-1, end_pos[3])
    else
        -- Manual construction for multiline selection
        by_line_any = {}
        by_line_bnd = {} -- Not used for multiline really
        nav_any = {}
        nav_bnd = {}
        
        -- We treat the whole block as one "target" for navigation logic, but for rendering we need line segments
        local s_lnum = start_pos[2] - 1
        local e_lnum = end_pos[2] - 1
        local s_col = start_pos[3] - 1
        local e_col = end_pos[3] -- 1-based inclusive from end_pos
        
        -- Add "target" (used for jump_to and counting)
        nav_any[1] = { lnum = s_lnum, col0 = s_col, col1 = e_col } 
        
        for l = s_lnum, e_lnum do
            local line_content = vim.api.nvim_buf_get_lines(bufnr, l, l+1, false)[1] or ''
            local c0 = (l == s_lnum) and s_col or 0
            local c1 = (l == e_lnum) and e_col or #line_content
            
            by_line_any[l] = { { col0 = c0, col1 = c1 } }
        end
        
        by_line_bnd = by_line_any -- Fallback
        nav_bnd = nav_any
    end
    
    local active_by_line = nil
    local nav_targets = nil

    -- Smart Pair Logic
    local function get_smart_pair(input_start)
        local pairs = {
            ['('] = ')',
            ['['] = ']',
            ['{'] = '}',
            ['<'] = '>',
            ['"'] = '"', -- Corrected: escaped double quote
            ["'"] = "'", -- Corrected: escaped single quote
            ['`'] = '`',
        }
        -- Only smart pair if it's exactly a single trigger character
        if #input_start == 1 and pairs[input_start] then
            return pairs[input_start]
        end
        return nil -- No smart pair
    end

    -- State for input
    local input_left = ''
    local input_right = ''
    local focus = 'left' -- 'left' or 'right'
    local right_is_dirty = false -- true if user manually edited the right side

    local function jump_to(step)
        if #nav_targets == 0 then return end
        if not cur_idx then
            cur_idx = (step >= 0) and 1 or #nav_targets
        else
            cur_idx = ((cur_idx - 1 + step) % #nav_targets) + 1
        end
        local m = nav_targets[cur_idx]
        if m then
            vim.api.nvim_win_set_cursor(0, { m.lnum + 1, m.col0 })
            pcall(function() vim.cmd('normal! zvzz') end)
        end
        return cur_idx
    end
    
    local function update_prompt()
        local cnt_total = #nav_targets
        local idx = cur_idx or (cnt_total > 0 and 1 or 0)
        local label = (mode == 'boundary') and 'boundary' or 'anywhere'
        local shown = literal
        if #shown > 20 then shown = shown:sub(1, 17) .. '…' end
        if not is_single_line then shown = '[Multiline Selection]' end
        
        -- Format prompt with visual indicator of focus
        local left_fmt = input_left
        local right_fmt = input_right
        
        if focus == 'left' then
            left_fmt = string.format('[%s]', left_fmt)
        else
            right_fmt = string.format('[%s]', right_fmt)
        end

        -- Show "Start" or "End" if empty to guide user
        if left_fmt == '[]' then left_fmt = '[Start]' end
        if right_fmt == '[]' then right_fmt = '[End]' end

        local wrap_preview = string.format('%s...%s', left_fmt, right_fmt)
        
        local prompt = string.format('[%d/%d] Wrap "%s" %s : %s', idx, cnt_total, shown, label, wrap_preview)
        vim.api.nvim_echo({{prompt, 'Normal'}}, false, {{}})
        vim.cmd('redraw')
    end
    
    local function rerender()
        clear_ns(bufnr)
        local prev_idx = cur_idx
        active_by_line = (mode == 'boundary') and by_line_bnd or by_line_any
        nav_targets    = (mode == 'boundary') and nav_bnd     or nav_any

        -- Use actual values for overlay
        local left = input_left
        local right = input_right
        
        local v_s = vim.fn.line('w0') - 1
        local v_e = vim.fn.line('w$') - 1
        for lnum = v_s, v_e do
            local list = active_by_line[lnum]
            if list then
            local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum+1, false)[1] or ''
            local segs = {}
            local idx = 0 
            for _, mm in ipairs(list) do
                local pre = line:sub(idx + 1, mm.col0)
                if #pre > 0 then segs[#segs+1] = { pre, 'Normal' } end
                
                -- The Wrap visualization
                -- Multiline logic: 
                -- If is_single_line: simple wrap.
                -- If not: 
                --   Is this the START of the block? (matches start_pos) -> add left fence
                --   Is this the END of the block? (matches end_pos) -> add right fence
                --   Wait, `list` entries in multiline manual mode are per line.
                --   We need to know if this segment is the very start or very end of the global match.
                --   But we only have per-line info in `list`.
                
                local is_start_node = false
                local is_end_node = false
                
                if is_single_line then
                    is_start_node = true
                    is_end_node = true
                else
                    -- Check against selection marks
                    if lnum == (start_pos[2]-1) and mm.col0 == (start_pos[3]-1) then is_start_node = true end
                    if lnum == (end_pos[2]-1) and mm.col1 == end_pos[3] then is_end_node = true end
                    -- Note: This logic is brittle if there are multiple matches, but for multiline we disabled global search, so it's fine.
                end

                if is_start_node and left ~= '' then segs[#segs+1] = { left, 'VisWrapFence' } end
                
                segs[#segs+1] = { line:sub(mm.col0 + 1, mm.col1), 'Normal' } -- The content itself
                
                if is_end_node and right ~= '' then segs[#segs+1] = { right, 'VisWrapFence' } end
                
                if (not is_start_node and not is_end_node) and left == '' and right == '' then
                     -- Highlight content if no input yet
                     -- Actually we do this above by default 'Normal' unless we want to highlight selection
                     -- Let's force VisWrapFence highlight if empty input
                     segs[#segs] = { line:sub(mm.col0 + 1, mm.col1), 'VisWrapFence' }
                end
                
                idx = mm.col1
            end
            local tail = line:sub(idx + 1)
            if #tail > 0 then segs[#segs+1] = { tail, 'Normal' } end
    
            if #segs > 0 then
                vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
                    virt_text = segs,
                    virt_text_win_col = 0,
                    virt_text_pos = 'overlay',
                    priority = 210,
                })
            end
            end
        end
    
        if #nav_targets == 0 then
            cur_idx = nil
        else
            if prev_idx and prev_idx >= 1 and prev_idx <= #nav_targets then
                cur_idx = prev_idx
            else
                local sel_index = nil
                for i, t in ipairs(nav_targets) do
                    if t.lnum == (start_pos[2]-1) and t.col0 == (start_pos[3]-1) and t.col1 == end_pos[3] then
                        sel_index = i; break
                    end
                end
                cur_idx = sel_index or 1
            end
        end
    
        update_prompt()
    end
    
    local final_left = ''
    local final_right = ''
    
    -- Always interactive now!
    rerender()
    while true do
        local key = vim.fn.getchar()
        local key_handler = function(k)
                local as_char = nil
                local trans_key = nil
                if type(k) == 'number' then
                    as_char = vim.fn.nr2char(k)
                    trans_key = vim.fn.keytrans(as_char)
                else
                    trans_key = vim.fn.keytrans(k)
                end
                local tl = string.lower(trans_key)

                if k == 9 or tl == '<tab>' then
                    -- Toggle focus
                    if focus == 'left' then
                        focus = 'right'
                    else
                        focus = 'left'
                    end
                    rerender()
                    return true -- continue loop
                elseif k == 13 or k == 10 or tl == '<cr>' then
                    -- Confirm
                    clear_ns(bufnr)
                    final_left = input_left
                    final_right = input_right
                    return false -- break loop
                elseif k == 27 or tl == '<esc>' then
                    -- Cancel
                    clear_ns(bufnr)
                    vim.fn.setpos('.', cursor_pos)
                    return false -- break loop
                elseif k == 8 or k == 127 or tl == '<bs>' or tl == '<c-h>' then
                    -- Backspace
                    if focus == 'left' then
                        input_left = input_left:sub(1, math.max(0, #input_left - 1))
                        if not right_is_dirty then
                            local pair = get_smart_pair(input_left)
                            input_right = pair or input_left
                        end
                    else
                        input_right = input_right:sub(1, math.max(0, #input_right - 1))
                        right_is_dirty = true
                    end
                    rerender()
                    return true
                elseif k == 14 or tl == '<c-n>' or trans_key == '^N' then
                    jump_to(1)
                    rerender()
                    return true
                elseif k == 16 or tl == '<c-p>' or trans_key == '^P' then
                    jump_to(-1)
                    rerender()
                    return true
                elseif tl == '<c-b>' then 
                    -- Boundary toggle (Ctrl-B)
                    if pattern_word then
                        mode = (mode == 'boundary') and 'anywhere' or 'boundary'
                    end
                    rerender()
                    return true
                else
                    -- Normal char
                    if as_char and as_char ~= '' and not (as_char:byte() < 32) then
                        if focus == 'left' then
                            input_left = input_left .. as_char
                            if not right_is_dirty then
                                local pair = get_smart_pair(input_left)
                                input_right = pair or input_left
                            end
                        else
                            input_right = input_right .. as_char
                            right_is_dirty = true
                        end
                        rerender()
                    end
                    return true
                end
        end

        -- Run the handler
        local cont = key_handler(key)
        if not cont then
            if final_left == '' and final_right == '' then return end -- Exit if empty or cancelled
            break
        end
    end
    
    local left = final_left
    local right = final_right

    -- Use a separator that isn't in pattern, left, or right
    local separators = { '/', '#', '%', '!', '@', '$', '^', '&', '*', '+', '=', '?', '|', '~' }
    local sep = nil
    for _, s in ipairs(separators) do
        if not pattern:find(s, 1, true) and not left:find(s, 1, true) and not right:find(s, 1, true) then
            sep = s
            break
        end
    end
    if not sep then
        print('VisWrap: could not find a suitable separator.')
        return
    end
    
    local regex_specials = '().%+-*?[]^$\\|/' -- Corrected: escaped backslash
    local esc_left = vim.fn.escape(left, sep .. '\\' .. regex_specials)
    local esc_right = vim.fn.escape(right, sep .. '\\' .. regex_specials)
    
    local clean_left = esc_left:gsub('&', '\\&') -- Corrected: escaped backslash
    local clean_right = esc_right:gsub('&', '\\&') -- Corrected: escaped backslash
    
    local replacement_string = clean_left .. '&' .. clean_right
    
    local active_pattern = (mode == 'boundary') and (pattern_word or pattern_any) or pattern_any
    
    local bufnr = vim.api.nvim_get_current_buf()
    local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)
    pcall(vim.cmd, ':%s' .. sep .. active_pattern .. sep .. replacement_string .. sep .. 'ge')
    
    local after_tick = vim.api.nvim_buf_get_changedtick(bufnr)
    
    -- Fallback for no global matches
    if after_tick == before_tick then
        local srow = start_pos[2] - 1
        local erow = end_pos[2] - 1
        local lines = vim.api.nvim_buf_get_lines(bufnr, srow, erow + 1, false)
        if #lines > 0 then
            local first_line = lines[1]
            local last_line = lines[#lines]
            local start_col1 = start_pos[3]
            local end_col1 = end_pos[3]
            
            if erow == srow then
                 if end_col1 > #first_line then end_col1 = #first_line end
            else
                 if end_col1 > #last_line then end_col1 = #last_line end
            end
            
            local prefix = first_line:sub(1, start_col1 - 1)
            local suffix = last_line:sub(end_col1 + 1)
            local content = ''
            
            if srow == erow then
                content = first_line:sub(start_col1, end_col1)
            else
                lines[1] = prefix .. left .. first_line:sub(start_col1)
                lines[#lines] = last_line:sub(1, end_col1) .. right .. suffix
                vim.api.nvim_buf_set_lines(bufnr, srow, erow+1, false, lines)
                vim.fn.setpos('.', cursor_pos)
                return
            end
            
            local new_line = prefix .. left .. content .. right .. suffix
            vim.api.nvim_buf_set_lines(bufnr, srow, srow + 1, false, { new_line })
        end
    end
    
    vim.fn.setpos('.', cursor_pos)
end

function M.run()
    return run()
end

return M
