if vim.g.vscode then
    return
end

local M = {}

-- VISREP
-- Replace visually selected text globally with a new string. Respects word boundaries, or not.

-- Scoped mode: <S-Tab> toggles manual scope selection.

local function clamp_col(line, col)
    local len = #line
    if col < 0 then return 0 end
    if col > len then return len end
    return col
end

local function next_byte(line, col)
    local char_idx = select(1, vim.str_utfindex(line, col))
    local last_idx = select(1, vim.str_utfindex(line, #line))
    if char_idx >= last_idx then
        return #line
    end
    local nb = vim.str_byteindex(line, char_idx + 1)
    if nb < 0 then nb = #line end
    return nb
end

local function marks_to_range(bufnr, smark, emark)
    if smark[1] == 0 or emark[1] == 0 then
        return nil
    end

    local srow = smark[1] - 1
    local scol = smark[2]
    local erow = emark[1] - 1
    local ecol = emark[2]
    if srow > erow or (srow == erow and scol > ecol) then
        srow, erow = erow, srow
        scol, ecol = ecol, scol
    end

    local sline = vim.api.nvim_buf_get_lines(bufnr, srow, srow + 1, false)[1] or ""
    local eline = vim.api.nvim_buf_get_lines(bufnr, erow, erow + 1, false)[1] or ""
    scol = clamp_col(sline, scol)
    ecol = clamp_col(eline, ecol)

    return {
        srow = srow,
        scol = scol,
        erow = erow,
        ecol = next_byte(eline, ecol),
    }
end

local function build_literal_core(text)
    local core = {}
    local chars = vim.fn.strchars(text)
    for ci = 0, chars - 1 do
        local ch = vim.fn.strcharpart(text, ci, 1)
        local cp = vim.fn.char2nr(ch, 1)
        if cp <= 0xFFFF then
            core[#core + 1] = string.format("\\%%u%04X", cp)
        else
            core[#core + 1] = string.format("\\%%U%08X", cp)
        end
    end
    return table.concat(core)
end

local function build_patterns(text)
    local is_single_line = not text:find("\n", 1, true)
    local literal_core = build_literal_core(text)
    local pattern_any = "\\V" .. literal_core
    local pattern_word = nil
    local defaults_to_boundary = is_single_line and (text:match("^[%w_]+$") ~= nil)

    if is_single_line then
        local b_char = "[^0-9A-Za-z_]"
        pattern_word = "\\m\\%(" .. "^\\|" .. b_char .. "\\)\\@<=" .. literal_core .. "\\%(" .. "$\\|" .. b_char .. "\\)\\@="
    end

    return {
        is_single_line = is_single_line,
        literal_core = literal_core,
        pattern_any = pattern_any,
        pattern_word = pattern_word,
        defaults_to_boundary = defaults_to_boundary,
    }
end

local function push_merged(list, col0, col1)
    local n = #list
    if n == 0 or col0 > list[n].col1 then
        list[n + 1] = { col0 = col0, col1 = col1 }
    elseif col1 > list[n].col1 then
        list[n].col1 = col1
    end
end

local function scan_regex_matches(bufnr, lnum, line, re, by_line, nav)
    if not re then return end
    local line_len = #line
    if line_len == 0 then return end

    local start = 0
    local list = nil
    while start <= line_len do
        local s, e = re:match_line(bufnr, lnum, start)
        if not s then break end

        local abs_s = start + s
        local abs_e = start + e
        if abs_e < abs_s then
            break
        end

        if abs_e == abs_s then
            start = abs_e + 1
        else
            list = list or {}
            push_merged(list, abs_s, abs_e)
            nav[#nav + 1] = { lnum = lnum, col0 = abs_s, col1 = abs_e }
            start = abs_e
        end
    end

    if list then
        by_line[lnum] = list
    end
end

local function build_match_index(bufnr, lines, re_any, re_bnd)
    local by_any = {}
    local by_bnd = {}
    local nav_any = {}
    local nav_bnd = {}

    if not re_any or not lines then
        return by_any, by_bnd, nav_any, nav_bnd
    end

    for lnum = 0, #lines - 1 do
        local line = lines[lnum + 1] or ""
        scan_regex_matches(bufnr, lnum, line, re_any, by_any, nav_any)
        if re_bnd then
            scan_regex_matches(bufnr, lnum, line, re_bnd, by_bnd, nav_bnd)
        end
    end

    if not re_bnd then
        by_bnd = by_any
        nav_bnd = nav_any
    end

    return by_any, by_bnd, nav_any, nav_bnd
end

local function match_in_scope(m, scope)
    if not scope then return true end
    local lnum = m.lnum
    if scope.block then
        if lnum < scope.srow or lnum > scope.erow then return false end
        return m.col0 >= scope.scol and m.col1 <= scope.ecol
    end
    if lnum < scope.srow or lnum > scope.erow then return false end
    if scope.srow == scope.erow then
        return m.col0 >= scope.scol and m.col1 <= scope.ecol
    end
    if lnum == scope.srow then
        return m.col0 >= scope.scol
    end
    if lnum == scope.erow then
        return m.col1 <= scope.ecol
    end
    return true
end

local function filter_by_scope(by_line, nav, scope)
    if not scope then return by_line, nav end

    local scoped_by_line = {}
    local scoped_nav = {}
    for i = 1, #nav do
        local m = nav[i]
        if match_in_scope(m, scope) then
            local list = scoped_by_line[m.lnum]
            if not list then
                list = {}
                scoped_by_line[m.lnum] = list
            end
            list[#list + 1] = m
            scoped_nav[#scoped_nav + 1] = m
        end
    end

    return scoped_by_line, scoped_nav
end

local function build_replaced_line(line, matches, repl)
    if not matches or #matches == 0 then return line end

    local parts = {}
    local prev_end = 0
    for _, mm in ipairs(matches) do
        if mm.col0 > prev_end then
            parts[#parts + 1] = line:sub(prev_end + 1, mm.col0)
        end
        if repl ~= "" then
            parts[#parts + 1] = repl
        end
        prev_end = mm.col1
    end
    parts[#parts + 1] = line:sub(prev_end + 1)
    return table.concat(parts)
end

local function apply_replacements_by_line(bufnr, by_line, repl)
    local line_nums = {}
    for lnum, _ in pairs(by_line) do
        line_nums[#line_nums + 1] = lnum
    end
    table.sort(line_nums)

    for i = 1, #line_nums do
        local lnum = line_nums[i]
        local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ""
        local new_line = build_replaced_line(line, by_line[lnum], repl)
        if new_line ~= line then
            vim.api.nvim_buf_set_lines(bufnr, lnum, lnum + 1, false, { new_line })
        end
    end
end

local function choose_separator(pattern, new_string)
    local separators = { "/", "#", "%", "!", "@", "$", "^", "&", "*", "+", "=", "?", "|", "~" }
    for _, s in ipairs(separators) do
        if not pattern:find(s, 1, true) and not new_string:find(s, 1, true) then
            return s
        end
    end
    return nil
end

local function replace_selected_region(bufnr, sel, new_string)
    local srow = sel.srow
    local erow = sel.erow

    local lines = vim.api.nvim_buf_get_lines(bufnr, srow, erow + 1, false)
    if #lines == 0 then
        return false
    end

    local first_line = lines[1]
    local last_line = lines[#lines]
    local start_col1 = sel.scol + 1
    local end_col1 = sel.ecol_excl

    local max_end_col = (erow == srow) and #first_line or #last_line
    if end_col1 > max_end_col then
        end_col1 = max_end_col
    end

    local prefix = first_line:sub(1, start_col1 - 1)
    local suffix = last_line:sub(end_col1 + 1)
    local rep_lines = vim.split(new_string, "\n", true)

    local new_lines
    if #rep_lines <= 1 then
        new_lines = { prefix .. new_string .. suffix }
    else
        new_lines = { prefix .. rep_lines[1] }
        for i = 2, #rep_lines - 1 do
            new_lines[#new_lines + 1] = rep_lines[i]
        end
        new_lines[#new_lines + 1] = rep_lines[#rep_lines] .. suffix
    end

    vim.api.nvim_buf_set_lines(bufnr, srow, erow + 1, false, new_lines)
    return true
end

local function get_preview_hl(lnum, col0)
    local ok, syn_id = pcall(vim.fn.synID, lnum + 1, col0 + 1, 1)
    if not ok or not syn_id or syn_id == 0 then
        return "VisrepText"
    end

    local trans_id = vim.fn.synIDtrans(syn_id)
    local name = vim.fn.synIDattr(trans_id, "name")
    if name and name ~= "" then
        return { "VisrepText", name }
    end

    return "VisrepText"
end

local function build_preview_marks(lnum, matches, repl)
    local marks = {}
    local use_inline = repl ~= ""
    for i = 1, #matches do
        local mm = matches[i]
        local opts = {
            end_col = mm.col1,
            conceal = "",
            priority = 210,
        }
        if use_inline then
            opts.virt_text = { { repl, get_preview_hl(lnum, mm.col0) } }
            opts.virt_text_pos = "inline"
        end
        marks[i] = { col = mm.col0, opts = opts }
    end
    return marks
end

local function enable_preview_conceal(winid, session)
    if session.preview_conceal_on then
        return
    end

    session.preview_conceal_on = true
    session.preview_winid = winid
    session.preview_restore_conceallevel = vim.api.nvim_get_option_value("conceallevel", { win = winid })
    session.preview_restore_concealcursor = vim.api.nvim_get_option_value("concealcursor", { win = winid })
    vim.api.nvim_set_option_value("conceallevel", 2, { win = winid })
    vim.api.nvim_set_option_value("concealcursor", "nv", { win = winid })
end

local function restore_preview_conceal(session)
    if not session.preview_conceal_on then
        return
    end

    local winid = session.preview_winid
    if winid and vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_set_option_value("conceallevel", session.preview_restore_conceallevel or 0, { win = winid })
        vim.api.nvim_set_option_value("concealcursor", session.preview_restore_concealcursor or "", { win = winid })
    end

    session.preview_conceal_on = false
    session.preview_winid = nil
    session.preview_restore_conceallevel = nil
    session.preview_restore_concealcursor = nil
end

local function run()
    local cursor_pos = vim.api.nvim_win_get_cursor(0) -- {line (1-based), col (0-based bytes)}
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()

    -- Visual selection bounds (byte-aware)
    local start_mark = vim.api.nvim_buf_get_mark(bufnr, '<') -- {line, col}
    local end_mark   = vim.api.nvim_buf_get_mark(bufnr, '>') -- {line, col}
    if start_mark[1] == 0 or end_mark[1] == 0 then
        return
    end
    pcall(vim.cmd, 'normal! \\<Esc>')

    -- Convert to 0-based rows and normalise ordering.
    local srow = start_mark[1] - 1
    local scol = start_mark[2]
    local erow = end_mark[1] - 1
    local ecol = end_mark[2]
    if srow > erow or (srow == erow and scol > ecol) then
        srow, erow = erow, srow
        scol, ecol = ecol, scol
    end

    local start_line = vim.api.nvim_buf_get_lines(bufnr, srow, srow + 1, false)[1] or ''
    local end_line   = vim.api.nvim_buf_get_lines(bufnr, erow, erow + 1, false)[1] or ''

    scol = clamp_col(start_line, scol)
    ecol = clamp_col(end_line, ecol)

    local end_excl = next_byte(end_line, ecol)

    local selection_lines = vim.api.nvim_buf_get_text(bufnr, srow, scol, erow, end_excl, {})
    local pattern = table.concat(selection_lines, '\n')
    local new_string = ''
    local sel = { srow = srow, scol = scol, erow = erow, ecol_excl = end_excl }
    
    -- Interactive input + preview (single-line selections only). For multi-line
    -- selections we fall back to a simple input prompt later.
    
    local patterns = build_patterns(pattern)
    local is_single_line = patterns.is_single_line
    local pattern_any = patterns.pattern_any
    local pattern_word = patterns.pattern_word
    
    -- Interactive preview: highlight matches and overlay the replacement as
    -- you type. Toggle boundary/anywhere with <Tab>, apply on <Enter>, cancel on <Esc>.
    local mode = (patterns.defaults_to_boundary and 'boundary') or 'anywhere'

    local ns = vim.api.nvim_create_namespace('VisrepPreview')
    local function clear_ns(bufnr)
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end

    -- lazy init highlight groups
    pcall(vim.api.nvim_set_hl, 0, 'VisrepText',  { link = 'IncSearch' })
    pcall(vim.api.nvim_set_hl, 0, 'VisrepScopeDim', { link = 'NonText' })
    
    local literal = pattern
    local lines_cache = nil
    local re_any = nil
    local re_bnd = nil
    if is_single_line and #literal > 0 then
        lines_cache = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        re_any = vim.regex(pattern_any)
        if pattern_word then
            re_bnd = vim.regex(pattern_word)
        end
    end
    local cur_idx = nil
    local sel_is_valid = false
    local scoped_enabled = false
    local scope_range = nil
    local by_line_any, by_line_bnd, nav_any, nav_bnd = build_match_index(bufnr, lines_cache, re_any, re_bnd)
    local active_by_line = nil
    local nav_targets = nil
    local session = { active = false }
    local function force_normal()
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        pcall(vim.api.nvim_feedkeys, esc, 'n', false)
        pcall(vim.cmd, 'stopinsert')
        pcall(vim.cmd, 'normal! \\<Esc>')
    end

    local function render_scope_dim(bufnr, scope)
        if not scope then return end
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        if line_count == 0 then return end
        local last_row = line_count - 1
        local last_line = vim.api.nvim_buf_get_lines(bufnr, last_row, last_row + 1, false)[1] or ''
        local last_col = #last_line

        if scope.srow > 0 or scope.scol > 0 then
            vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
                end_row = scope.srow,
                end_col = scope.scol,
                hl_group = 'VisrepScopeDim',
                hl_eol = true,
                priority = 100,
            })
        end

        if scope.erow < last_row or scope.ecol < last_col then
            vim.api.nvim_buf_set_extmark(bufnr, ns, scope.erow, scope.ecol, {
                end_row = last_row,
                end_col = last_col,
                hl_group = 'VisrepScopeDim',
                hl_eol = true,
                priority = 100,
            })
        end
    end
    
    local function jump_to(step)
        if #nav_targets == 0 then return end
        if not cur_idx or cur_idx <= 0 then
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
        local idx = cur_idx or 0
        local label = (mode == 'boundary') and 'boundary' or 'anywhere'
        local scope_tag = scoped_enabled and ' [scoped]' or ''
        local shown = literal
        local max_len = 77
        local shown_len = vim.fn.strchars(shown)
        if shown_len > max_len then
            shown = vim.fn.strcharpart(shown, 0, max_len) .. '…'
        end
        local prompt = string.format('[%d/%d] Replace "%s" %s%s with: %s', idx, cnt_total, shown, label, scope_tag, repl or '')
        vim.api.nvim_echo({{prompt, 'Normal'}}, false, {})
        vim.cmd('redraw')
    end
    
    local scope_maps_active = false
    local function clear_scope_maps()
        if not scope_maps_active then
            return
        end
        pcall(vim.keymap.del, { 'n', 'v' }, '<CR>', { buffer = bufnr })
        pcall(vim.keymap.del, { 'n', 'v' }, '<Esc>', { buffer = bufnr })
        scope_maps_active = false
    end

    local function finish_scope_selection(picked)
        clear_scope_maps()
        force_normal()
        if picked then
            scope_range = picked
            scoped_enabled = true
        else
            scope_range = nil
            scoped_enabled = false
        end
        if not session.active then
            return
        end
        vim.schedule(function()
            if not session.active then
                return
            end
            local action = session.input_loop()
            if action == "apply" then
                session.finalize()
                session.active = false
                M._visrep_session = nil
            elseif action == "cancel" then
                session.active = false
                M._visrep_session = nil
            end
        end)
    end

    local function begin_scope_selection()
        clear_ns(bufnr)
        restore_preview_conceal(session)
        vim.api.nvim_echo({{ "Visrep: select scope and press <Enter> (or <Esc> to cancel)", "ModeMsg" }}, false, {})
        vim.cmd('redraw')

        scope_maps_active = true
        vim.keymap.set({ 'n', 'v' }, '<CR>', function()
            local mode_now = vim.fn.mode()
            local smark
            local emark
            if mode_now == 'V' then
                local vpos = vim.fn.getpos('v')
                local cpos = vim.fn.getpos('.')
                local sline = math.min(vpos[2], cpos[2])
                local eline = math.max(vpos[2], cpos[2])
                local end_line = vim.api.nvim_buf_get_lines(bufnr, eline - 1, eline, false)[1] or ''
                smark = { sline, 0 }
                emark = { eline, #end_line }
            elseif mode_now == '\22' then
                local vpos = vim.fn.getpos('v')
                local cpos = vim.fn.getpos('.')
                local sline = math.min(vpos[2], cpos[2])
                local eline = math.max(vpos[2], cpos[2])
                local scol = math.max(0, math.min(vpos[3], cpos[3]) - 1)
                local ecol = math.max(0, math.max(vpos[3], cpos[3]) - 1)
                smark = { sline, scol }
                emark = { eline, ecol }
            elseif mode_now:find('[vV\22]') then
                local vpos = vim.fn.getpos('v')
                local cpos = vim.fn.getpos('.')
                smark = { vpos[2], math.max(0, vpos[3] - 1) }
                emark = { cpos[2], math.max(0, cpos[3] - 1) }
            else
                smark = vim.api.nvim_buf_get_mark(bufnr, '<')
                emark = vim.api.nvim_buf_get_mark(bufnr, '>')
            end
            local picked = marks_to_range(bufnr, smark, emark)
            if picked and mode_now == '\22' then
                picked.block = true
            end
            finish_scope_selection(picked)
        end, { buffer = bufnr, silent = true, nowait = true })
        vim.keymap.set({ 'n', 'v' }, '<Esc>', function()
            finish_scope_selection(nil)
        end, { buffer = bufnr, silent = true, nowait = true })
    end

    local function rerender(repl)
        clear_ns(bufnr)
        local prev_idx = cur_idx
        -- Select active line-index and nav list by mode, then filter by scope.
        local base_by_line = (mode == 'boundary') and by_line_bnd or by_line_any
        local base_nav     = (mode == 'boundary') and nav_bnd     or nav_any

        local active_scope = scoped_enabled and scope_range or nil
        active_by_line, nav_targets = filter_by_scope(base_by_line, base_nav, active_scope)

        if active_scope then
            render_scope_dim(bufnr, active_scope)
        end

        local repl_txt = repl or ''

        if next(active_by_line) then
            enable_preview_conceal(winid, session)
            for lnum, list in pairs(active_by_line) do
                local marks = build_preview_marks(lnum, list, repl_txt)
                for i = 1, #marks do
                    local mark = marks[i]
                    vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, mark.col, mark.opts)
                end
            end
        else
            restore_preview_conceal(session)
        end

        sel_is_valid = false
        local sel_index = nil
        for i, t in ipairs(nav_targets) do
            if t.lnum == sel.srow and t.col0 == sel.scol and t.col1 == sel.ecol_excl then
                sel_index = i
                break
            end
        end
        sel_is_valid = sel_index ~= nil

        -- choose current index: keep previous if possible (when selection is valid), else prefer selection, else 0
        if #nav_targets == 0 then
            cur_idx = 0
        elseif sel_is_valid then
            if prev_idx and prev_idx >= 1 and prev_idx <= #nav_targets then
                cur_idx = prev_idx
            else
                cur_idx = sel_index
            end
        else
            cur_idx = 0
        end

        update_prompt(repl)
    end

    local function finalize()
        force_normal()
        restore_preview_conceal(session)
        if is_single_line then
            if not nav_targets or #nav_targets == 0 then
                force_normal()
                vim.api.nvim_win_set_cursor(0, cursor_pos)
                session.active = false
                M._visrep_session = nil
                return
            end
            if scoped_enabled and scope_range then
                apply_replacements_by_line(bufnr, active_by_line, new_string)
                force_normal()
                vim.api.nvim_win_set_cursor(0, cursor_pos)
                session.active = false
                M._visrep_session = nil
                return
            end
        end

        -- Pick a separator that is not in pattern or new_string
        local sep = choose_separator(pattern, new_string)
        if not sep then
            print('Visrep: could not find a suitable separator.')
            force_normal()
            session.active = false
            M._visrep_session = nil
            return
        end

        local regex_specials = '().%+-*?[]^$\\|/'
        local escaped_new_string = vim.fn.escape(new_string, sep .. '\\' .. regex_specials)

        -- Choose the active pattern based on preview mode.
        local active_pattern = (mode == 'boundary') and (pattern_word or pattern_any) or pattern_any

        -- Perform the substitution globally; add 'e' to suppress errors when not found.
        local before_tick = vim.api.nvim_buf_get_changedtick(bufnr)
        pcall(vim.cmd, ':%s' .. sep .. active_pattern .. sep .. escaped_new_string .. sep .. 'ge')

        local after_tick = vim.api.nvim_buf_get_changedtick(bufnr)
        if after_tick == before_tick then
            -- No global matches: replace the originally selected region only.
            if not replace_selected_region(bufnr, sel, new_string) then
                force_normal()
                vim.api.nvim_win_set_cursor(0, cursor_pos)
                session.active = false
                M._visrep_session = nil
                return
            end
        end

        -- Restore the cursor position
        force_normal()
        vim.api.nvim_win_set_cursor(0, cursor_pos)
        session.active = false
        M._visrep_session = nil
    end
    
    if is_single_line then
        local input = ''
        local function input_loop()
            rerender(input)
            while true do
                local key = vim.fn.getchar()
                if type(key) == 'number' then
                    local as_char = vim.fn.nr2char(key)
                    local trans_num = as_char and vim.fn.keytrans(as_char) or ''
                    local trans_num_l = string.lower(trans_num or '')
                    if trans_num_l == '<s-tab>' then -- Shift-Tab (toggle scope)
                        if scoped_enabled then
                            scoped_enabled = false
                            scope_range = nil
                            rerender(input)
                        else
                            begin_scope_selection()
                            return "defer"
                        end
                    elseif key == 9 or trans_num_l == '<tab>' then -- Tab
                        if pattern_word then
                            mode = (mode == 'boundary') and 'anywhere' or 'boundary'
                        end
                        rerender(input)
                    elseif key == 13 or trans_num_l == '<cr>' then -- Enter
                        clear_ns(bufnr)
                        restore_preview_conceal(session)
                        new_string = input
                        return "apply"
                    elseif key == 27 or trans_num_l == '<esc>' then -- Esc
                        clear_ns(bufnr)
                        restore_preview_conceal(session)
                        vim.api.nvim_win_set_cursor(0, cursor_pos)
                        return "cancel"
                    elseif key == 8 or key == 127 or trans_num_l == '<bs>' or trans_num_l == '<c-h>' then -- Backspace
                        input = input:sub(1, math.max(0, #input - 1))
                        rerender(input)
                    elseif key == 14 or trans_num_l == '<c-n>' or trans_num == '^N' then -- Ctrl-N
                        if sel_is_valid then
                            jump_to(1)
                            rerender(input)
                        end
                    elseif key == 16 or trans_num_l == '<c-p>' or trans_num == '^P' then -- Ctrl-P
                        if sel_is_valid then
                            jump_to(-1)
                            rerender(input)
                        end
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
                    if tl == '<s-tab>' then
                        if scoped_enabled then
                            scoped_enabled = false
                            scope_range = nil
                            rerender(input)
                        else
                            begin_scope_selection()
                            return "defer"
                        end
                    elseif tl == '<tab>' then
                        if pattern_word then
                            mode = (mode == 'boundary') and 'anywhere' or 'boundary'
                        end
                        rerender(input)
                    elseif tl == '<cr>' then
                        clear_ns(bufnr)
                        restore_preview_conceal(session)
                        new_string = input
                        return "apply"
                    elseif tl == '<esc>' then
                        clear_ns(bufnr)
                        restore_preview_conceal(session)
                        vim.api.nvim_win_set_cursor(0, cursor_pos)
                        return "cancel"
                    elseif tl == '<bs>' or tl == '<c-h>' then
                        input = input:sub(1, math.max(0, #input - 1))
                        rerender(input)
                    elseif tl == '<c-n>' or trans == '^N' then
                        if sel_is_valid then
                            jump_to(1)
                            rerender(input)
                        end
                    elseif tl == '<c-p>' or trans == '^P' then
                        if sel_is_valid then
                            jump_to(-1)
                            rerender(input)
                        end
                    else
                        -- ignore other specials
                    end
                end
            end
        end

        session.input_loop = input_loop
        session.finalize = finalize
        session.active = true
        M._visrep_session = session

        local action = input_loop()
        if action == "defer" then
            return
        end
        if action == "cancel" then
            session.active = false
            M._visrep_session = nil
            return
        end
    else
        -- Multi-line selection: simpler prompt with no live preview
        new_string = vim.fn.input(string.format('Replace "%s" with: ', pattern))
        if new_string == '' then return end
    end

    finalize()
end

function M.run()
    return run()
end

function M._reset_for_tests()
    M._visrep_session = nil
end

M._test = {
    clamp_col = clamp_col,
    next_byte = next_byte,
    marks_to_range = marks_to_range,
    build_literal_core = build_literal_core,
    build_patterns = build_patterns,
    push_merged = push_merged,
    scan_regex_matches = scan_regex_matches,
    build_match_index = build_match_index,
    match_in_scope = match_in_scope,
    filter_by_scope = filter_by_scope,
    build_replaced_line = build_replaced_line,
    apply_replacements_by_line = apply_replacements_by_line,
    choose_separator = choose_separator,
    replace_selected_region = replace_selected_region,
    get_preview_hl = get_preview_hl,
    build_preview_marks = build_preview_marks,
    enable_preview_conceal = enable_preview_conceal,
    restore_preview_conceal = restore_preview_conceal,
}

return M
