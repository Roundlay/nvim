if vim.g.vscode then
    return
end

local M = {}

-- VISREP
-- Replace visually selected text globally with a new string. Respects word boundaries, or not.


-- [ ] You know it would be cool if the VISREP command area just worked like Neovim. I.e. modal editing in there.
-- [ ] TODO Ensure that the first item in the [N/N] list is the one we started with, not the literal first.
-- [ ] TODO Config: Add standard plugin configuration options.
-- [ ] TODO Config: default mode. Add `vim.g.visrep_default_mode = 'boundary'|'anywhere'`.
-- [ ] TODO Config: preview scope. Add `vim.g.visrep_preview = 'viewport'|'global'|'auto'` and `vim.g.visrep_preview_margin = 10` (extra lines above/below viewport).
-- [ ] TODO Theming: expose highlight groups (e.g. VisrepText) as user-configurable.
-- [ ] TODO Debounce: Coalesce rapid keystrokes with ~10–20ms debounce for rerender.
-- [ ] TODO Async index: Implement async build for very large files (>100k lines)?
-- [ ] TODO Unicode boundaries: Use 'iskeyword' or Vim regex classes to widen beyond ASCII.
-- [ ] TODO Multi-line live preview: Extend overlay builder to selections with newlines.
-- [ ] TODO Incremental viewport updates: Diff previous/next visible ranges; update only changed lines.
-- [ ] TODO Case behavior: Option to toggle case sensitivity (e.g. smartcase) per invocation.
-- [?] How should we handle situations where the user wants to replace something with *nothing*?
-- [?] What are the biggest pain points of the default %s search and replace that you're trying to remedy here?

local function run()
    local cursor_pos = vim.fn.getpos('.')
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local selected_text = vim.fn.getline(start_pos[2], end_pos[2])
    local pattern = ''
    local new_string = ''
    
    -- Concatenate selected lines into a single string
    for i, line in ipairs(selected_text) do
        if i > 1 then
            pattern = pattern .. '\n'
        end
        local start_col = (i == 1) and start_pos[3] or 1
        local end_col = (i == #selected_text) and end_pos[3] or #line
        pattern = pattern .. line:sub(start_col, end_col)
    end
    
    -- Interactive input + preview (single-line selections only). For multi-line
    -- selections we fall back to a simple input prompt later.
    
    -- Decide whether to enforce word boundaries.
    -- Only apply when the selection is a single line and looks like a keyword.
    local is_single_line = not pattern:find('\n', 1, true)
    local is_wordlike = is_single_line and (pattern:match('^[%w_]+$') ~= nil)
    
    -- Build literal core as sequence of byte matches for robustness.
    local core = {}
    for i = 1, #pattern do
        core[#core+1] = string.format('\\%%x%02X', pattern:byte(i))
    end
    local literal_core = table.concat(core)
    
    local pattern_any   = '\\V' .. literal_core
    local pattern_word  = is_wordlike and ('\\V\\<' .. literal_core .. '\\>') or nil
    
    -- Interactive preview: highlight matches and overlay the replacement as
    -- you type. Toggle boundary/anywhere with <Tab>, apply on <Enter>, cancel on <Esc>.
    local mode = (pattern_word and 'boundary') or 'anywhere'
    
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
        -- ensure selection present in both maps and nav lists
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
    
    local ns = vim.api.nvim_create_namespace('VisrepPreview')
    local function clear_ns(bufnr)
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
    
    -- lazy init highlight groups
    pcall(vim.api.nvim_set_hl, 0, 'VisrepText',  { link = 'IncSearch' })
    
    local bufnr = vim.api.nvim_get_current_buf()
    local literal = pattern
    local cur_idx = nil
    local by_line_any, by_line_bnd, nav_any, nav_bnd = build_match_index(bufnr, literal, start_pos[2]-1, start_pos[3]-1, end_pos[3])
    local active_by_line = nil
    local nav_targets = nil
    
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
    
    local function update_prompt(repl)
        local cnt_total = #nav_targets
        local idx = cur_idx or (cnt_total > 0 and 1 or 0)
        local label = (mode == 'boundary') and 'boundary' or 'anywhere'
        local shown = literal
        if #shown > 30 then shown = shown:sub(1, 27) .. '…' end
        local prompt = string.format('[%d/%d] Replace "%s" %s with: %s', idx, cnt_total, shown, label, repl or '')
        vim.api.nvim_echo({{prompt, 'Normal'}}, false, {})
        vim.cmd('redraw')
    end
    
    local function rerender(repl)
        clear_ns(bufnr)
        local prev_idx = cur_idx
        -- Select active line-index and nav list by mode
        active_by_line = (mode == 'boundary') and by_line_bnd or by_line_any
        nav_targets    = (mode == 'boundary') and nav_bnd     or nav_any
    
        -- For visible range only, overlay the full preview line using virt_text segments
        local v_s = vim.fn.line('w0') - 1
        local v_e = vim.fn.line('w$') - 1
        for lnum = v_s, v_e do
            local list = active_by_line[lnum]
            if list then
            local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum+1, false)[1] or ''
            local segs = {}
            local idx = 0 -- 0-based consumed end
            for _, mm in ipairs(list) do
                -- prefix text
                local pre = line:sub(idx + 1, mm.col0)
                if #pre > 0 then segs[#segs+1] = { pre, 'Normal' } end
                -- replacement
                if repl and repl ~= '' then
                    segs[#segs+1] = { repl, 'VisrepText' }
                end
                idx = mm.col1
            end
            -- tail
            local tail = line:sub(idx + 1)
            if #tail > 0 then segs[#segs+1] = { tail, 'Normal' } end
    
            -- If no repl text (empty), segs may be only pre+tail which is fine
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
    
        -- choose current index: keep previous if possible, else prefer selection, else 1
        if #nav_targets == 0 then
            cur_idx = nil
        else
            if prev_idx and prev_idx >= 1 and prev_idx <= #nav_targets then
                cur_idx = prev_idx
            else
                -- prefer selection index if present
                local sel_index = nil
                for i, t in ipairs(nav_targets) do
                    if t.lnum == (start_pos[2]-1) and t.col0 == (start_pos[3]-1) and t.col1 == end_pos[3] then
                        sel_index = i; break
                    end
                end
                cur_idx = sel_index or 1
            end
        end
    
        update_prompt(repl)
    end
    
    if is_single_line then
        local input = ''
        rerender(input)
        while true do
            local key = vim.fn.getchar()
            if type(key) == 'number' then
                local as_char = vim.fn.nr2char(key)
                local trans_num = as_char and vim.fn.keytrans(as_char) or ''
                local trans_num_l = string.lower(trans_num or '')
                if key == 9 or trans_num_l == '<tab>' then -- Tab
                    if pattern_word then
                        mode = (mode == 'boundary') and 'anywhere' or 'boundary'
                    end
                    rerender(input)
                elseif key == 13 or key == 10 or trans_num_l == '<cr>' then -- Enter
                    clear_ns(bufnr)
                    new_string = input
                    break
                elseif key == 27 or trans_num_l == '<esc>' then -- Esc
                    clear_ns(bufnr)
                    vim.fn.setpos('.', cursor_pos)
                    return
                elseif key == 8 or key == 127 or trans_num_l == '<bs>' or trans_num_l == '<c-h>' then -- Backspace
                    input = input:sub(1, math.max(0, #input - 1))
                    rerender(input)
                elseif key == 14 or trans_num_l == '<c-n>' or trans_num == '^N' then -- Ctrl-N
                    jump_to(1)
                    rerender(input)
                elseif key == 16 or trans_num_l == '<c-p>' or trans_num == '^P' then -- Ctrl-P
                    jump_to(-1)
                    rerender(input)
                else
                    local ch = as_char
                    if ch and ch ~= '' then
                        input = input .. ch
                        rerender(input)
                    end
                end
            else
                -- Special key sequence as string; normalize with keytrans
                local trans = vim.fn.keytrans(key)
                local tl = string.lower(trans)
                if tl == '<tab>' then
                    if pattern_word then
                        mode = (mode == 'boundary') and 'anywhere' or 'boundary'
                    end
                    rerender(input)
                elseif tl == '<cr>' then
                    clear_ns(bufnr)
                    new_string = input
                    break
                elseif tl == '<esc>' then
                    clear_ns(bufnr)
                    vim.fn.setpos('.', cursor_pos)
                    return
                elseif tl == '<bs>' or tl == '<c-h>' then
                    input = input:sub(1, math.max(0, #input - 1))
                    rerender(input)
                elseif tl == '<c-n>' or trans == '^N' then
                    jump_to(1)
                    rerender(input)
                elseif tl == '<c-p>' or trans == '^P' then
                    jump_to(-1)
                    rerender(input)
                else
                    -- ignore other specials
                end
            end
        end
    else
        -- Multi-line selection: simpler prompt with no live preview
        new_string = vim.fn.input(string.format('Replace "%s" with: ', pattern))
        if new_string == '' then return end
    end
    
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
        print('Visrep: could not find a suitable separator.')
        return
    end
    
    local regex_specials = '().%+-*?[]^$\\|/'
    local escaped_new_string = vim.fn.escape(new_string, sep .. '\\' .. regex_specials)
    
    -- Choose the active pattern based on preview mode.
    local active_pattern = (mode == 'boundary') and (pattern_word or pattern_any) or pattern_any
    
    -- Perform the substitution globally; add 'e' to suppress errors when not found.
    local bufnr = vim.api.nvim_get_current_buf()
    local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)
    pcall(vim.cmd, ':%s' .. sep .. active_pattern .. sep .. escaped_new_string .. sep .. 'ge')
    
    local after_tick = vim.api.nvim_buf_get_changedtick(bufnr)
    if after_tick == before_tick then
        -- No global matches: replace the originally selected region only.
        local srow = start_pos[2] - 1
        local erow = end_pos[2] - 1
    
        local lines = vim.api.nvim_buf_get_lines(bufnr, srow, erow + 1, false)
        if #lines == 0 then
            vim.fn.setpos('.', cursor_pos)
            return
        end
    
        local first_line = lines[1]
        local last_line  = lines[#lines]
    
        local start_col1 = start_pos[3] -- 1-based inclusive
        local end_col1   = end_pos[3]   -- 1-based inclusive (may be huge for linewise)
    
        -- Clamp end column for safety
        if erow == srow then
            if end_col1 > #first_line then end_col1 = #first_line end
        else
            if end_col1 > #last_line then end_col1 = #last_line end
        end
    
        local prefix = first_line:sub(1, start_col1 - 1)
        local suffix = last_line:sub(end_col1 + 1)
    
        local rep_lines = vim.split(new_string, "\n", true)
    
        local new_lines
        if srow == erow then
            if #rep_lines <= 1 then
                new_lines = { prefix .. new_string .. suffix }
            else
                new_lines = {}
                new_lines[1] = prefix .. rep_lines[1]
                for i = 2, #rep_lines - 1 do new_lines[#new_lines + 1] = rep_lines[i] end
                new_lines[#new_lines + 1] = rep_lines[#rep_lines] .. suffix
            end
        else
            if #rep_lines <= 1 then
                new_lines = { prefix .. new_string .. suffix }
            else
                new_lines = {}
                new_lines[1] = prefix .. rep_lines[1]
                for i = 2, #rep_lines - 1 do new_lines[#new_lines + 1] = rep_lines[i] end
                new_lines[#new_lines + 1] = rep_lines[#rep_lines] .. suffix
            end
        end
    
        vim.api.nvim_buf_set_lines(bufnr, srow, erow + 1, false, new_lines)
    end
    
    -- Restore the cursor position
    vim.fn.setpos('.', cursor_pos)
end

function M.run()
    return run()
end

return M
