local api = vim.api
local fn = vim.fn

local M = {}

local config = require("wrappin.config")
local state = require("wrappin.state")

local BLOCK_BLANK = "blank"
local BLOCK_TEXT = "text"
local BLOCK_PLAIN = "plain"
local BLOCK_COMMENT = "comment"
local BLOCK_BULLET = "bullet"
local BLOCK_ORDERED = "ordered"
local BLOCK_HEADING = "heading"

local function normalize_range(start_line, end_line)
    if type(start_line) ~= "number" or type(end_line) ~= "number" then
        return nil, nil
    end

    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end

    return start_line, end_line
end

local function get_mark_range()
    local start_line = fn.getpos("'<")[2] - 1
    local end_line = fn.getpos("'>")[2] - 1

    if start_line < 0 or end_line < 0 then
        return nil, nil
    end

    return normalize_range(start_line, end_line)
end

local function get_live_visual_range()
    local cursor_line = fn.line(".")
    local visual_line = fn.line("v")

    if cursor_line <= 0 or visual_line <= 0 then
        return nil, nil
    end

    return normalize_range(cursor_line - 1, visual_line - 1)
end

local function exit_visual_mode()
    local mode = api.nvim_get_mode().mode
    if mode == "v" or mode == "V" or mode == "\22" then
        api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    end
end

local function restore_cursor(cursor_line, cursor_col)
    if type(cursor_line) ~= "number" then
        return
    end

    local line_count = api.nvim_buf_line_count(0)
    local target_line = math.min(math.max(cursor_line, 1), line_count)
    local line = api.nvim_buf_get_lines(0, target_line - 1, target_line, false)[1] or ""
    local max_col = math.max(#line - 1, 0)
    local target_col = math.min(math.max(cursor_col or 0, 0), max_col)

    api.nvim_win_set_cursor(0, { target_line, target_col })
end

local function display_width(text, start_col)
    return fn.strdisplaywidth(text, start_col or 0)
end

local function build_prefixed_row(raw, kind, indent_text, marker_text, marker_spacing, body_text)
    local first_prefix = indent_text .. marker_text .. marker_spacing
    local continuation_prefix

    if kind == BLOCK_COMMENT then
        continuation_prefix = first_prefix
    else
        continuation_prefix = indent_text .. string.rep(" ", display_width(marker_text .. marker_spacing))
    end

    return {
        raw = raw,
        kind = kind,
        indent_text = indent_text,
        marker_text = marker_text,
        marker_spacing = marker_spacing,
        body_text = body_text,
        first_prefix = first_prefix,
        continuation_prefix = continuation_prefix,
    }
end

local function build_text_profile(text)
    local profile = {
        word_count = 0,
        punctuation_count = 0,
        starts_with_closer = false,
        starts_with_word = false,
        starts_with_code_keyword = false,
        ends_with_clause_keyword = false,
        has_brace = false,
        has_semicolon = false,
        has_assignment = false,
        has_compare = false,
        has_logic = false,
        has_member_access = false,
        has_call_parens = false,
    }

    if text == nil or text == "" then
        return profile
    end

    for _ in text:gmatch("%S+") do
        profile.word_count = profile.word_count + 1
    end

    profile.punctuation_count = select(2, text:gsub("[{}%[%]%(%)%;,]", ""))
    profile.starts_with_closer = text:match("^%s*[%]%}%)]") ~= nil
    profile.starts_with_word = text:match("^%s*[\"'`%a_]") ~= nil
    profile.starts_with_code_keyword = text:match("^%s*(local%s+function|local|function|if|elseif|else|for|while|repeat|until|return|end)%f[%W]") ~= nil
    profile.ends_with_clause_keyword = text:match("%f[%w](then|do|end)%s*$") ~= nil
    profile.has_brace = text:find("[{}]") ~= nil
    profile.has_semicolon = text:find(";", 1, true) ~= nil
    profile.has_assignment = text:find(" = ", 1, true) ~= nil
        or text:find("+=", 1, true) ~= nil
        or text:find("-=", 1, true) ~= nil
        or text:find("*=", 1, true) ~= nil
        or text:find("/=", 1, true) ~= nil
        or text:find("%=", 1, true) ~= nil
    profile.has_compare = text:find("==", 1, true) ~= nil
        or text:find("!=", 1, true) ~= nil
        or text:find("<=", 1, true) ~= nil
        or text:find(">=", 1, true) ~= nil
    profile.has_logic = text:find("&&", 1, true) ~= nil
        or text:find("||", 1, true) ~= nil
    profile.has_member_access = text:find("->", 1, true) ~= nil
        or text:find("::", 1, true) ~= nil
        or text:match("[%w_%)%]]+%.%a[%w_]*") ~= nil
    profile.has_call_parens = text:match("[%a_][%w_%.:]*%b()") ~= nil

    return profile
end

local function parse_row(raw)
    local indent_text = raw:match("^(%s*)") or ""
    local rest = raw:sub(#indent_text + 1)

    if rest == "" then
        return {
            raw = raw,
            kind = BLOCK_BLANK,
            indent_text = indent_text,
            body_text = "",
            text_profile = build_text_profile(""),
        }
    end

    local marker_text, marker_spacing, body_text

    marker_text, marker_spacing, body_text = rest:match("^(#+)(%s+)(.*)$")
    if marker_text ~= nil then
        local row = build_prefixed_row(raw, BLOCK_HEADING, indent_text, marker_text, marker_spacing, body_text)
        row.text_profile = build_text_profile(body_text)
        return row
    end

    marker_text, marker_spacing, body_text = rest:match("^(%d+[.)])(%s+)(.*)$")
    if marker_text ~= nil then
        local row = build_prefixed_row(raw, BLOCK_ORDERED, indent_text, marker_text, marker_spacing, body_text)
        row.text_profile = build_text_profile(body_text)
        return row
    end

    marker_text, marker_spacing, body_text = rest:match("^([%-%+%*])(%s+)(.*)$")
    if marker_text ~= nil then
        local row = build_prefixed_row(raw, BLOCK_BULLET, indent_text, marker_text, marker_spacing, body_text)
        row.text_profile = build_text_profile(body_text)
        return row
    end

    marker_text, marker_spacing, body_text = rest:match("^(//+)(%s*)(.*)$")
    if marker_text ~= nil then
        local row = build_prefixed_row(raw, BLOCK_COMMENT, indent_text, marker_text, marker_spacing, body_text)
        row.text_profile = build_text_profile(body_text)
        return row
    end

    marker_text, marker_spacing, body_text = rest:match("^(%-%-+)(%s*)(.*)$")
    if marker_text ~= nil then
        local row = build_prefixed_row(raw, BLOCK_COMMENT, indent_text, marker_text, marker_spacing, body_text)
        row.text_profile = build_text_profile(body_text)
        return row
    end

    marker_text, marker_spacing, body_text = rest:match("^(;+)(%s*)(.*)$")
    if marker_text ~= nil then
        local row = build_prefixed_row(raw, BLOCK_COMMENT, indent_text, marker_text, marker_spacing, body_text)
        row.text_profile = build_text_profile(body_text)
        return row
    end

    return {
        raw = raw,
        kind = BLOCK_TEXT,
        indent_text = indent_text,
        body_text = rest,
        first_prefix = indent_text,
        continuation_prefix = indent_text,
        text_profile = build_text_profile(rest),
    }
end

local function parse_lines(lines)
    local rows = {}

    for i = 1, #lines do
        rows[i] = parse_row(lines[i])
    end

    return rows
end

local function append_words(words, text)
    if text == nil or text == "" then
        return
    end

    local code_part, comment_part = text:match("^(.-)%s*(//.*)$")

    if comment_part ~= nil then
        for word in code_part:gmatch("%S+") do
            words[#words + 1] = word
        end
        words[#words + 1] = comment_part
        return
    end

    for word in text:gmatch("%S+") do
        words[#words + 1] = word
    end
end

local function build_block(kind, first_prefix, continuation_prefix)
    return {
        kind = kind,
        first_prefix = first_prefix,
        continuation_prefix = continuation_prefix,
        words = {},
    }
end

local function flush_block(segments, block)
    if block ~= nil then
        segments[#segments + 1] = block
    end
end

local is_context_passthrough_row

local function derive_inherited_schema(before_rows)
    local required_prefix

    for i = #before_rows, 1, -1 do
        local row = before_rows[i]

        if row.kind == BLOCK_BLANK then
            return nil
        end

        if row.kind == BLOCK_TEXT then
            if required_prefix == nil then
                required_prefix = row.first_prefix
            elseif row.first_prefix ~= required_prefix then
                return nil
            end

            if not is_context_passthrough_row(row) then
                return nil
            end
        else
            if required_prefix ~= nil and row.continuation_prefix ~= required_prefix then
                return nil
            end

            return {
                kind = row.kind,
                first_prefix = row.continuation_prefix,
                continuation_prefix = row.continuation_prefix,
            }
        end
    end

    return nil
end

local function score_code_profile(profile)
    local score = 0

    if profile.starts_with_code_keyword then
        score = score + 4
    end
    if profile.ends_with_clause_keyword then
        score = score + 3
    end
    if profile.starts_with_closer then
        score = score + 4
    end
    if profile.has_brace then
        score = score + 4
    end
    if profile.has_semicolon then
        score = score + 4
    end
    if profile.has_member_access then
        score = score + 3
    end
    if profile.has_assignment then
        score = score + 3
    end
    if profile.has_compare then
        score = score + 3
    end
    if profile.has_logic then
        score = score + 2
    end
    if profile.has_call_parens then
        score = score + 2
    end
    if profile.punctuation_count >= 3 then
        score = score + 1
    end

    return score
end

local function score_continuation_profile(profile)
    local score = 0

    if profile.word_count >= 4 then
        score = score + 4
    elseif profile.word_count >= 2 then
        score = score + 2
    elseif profile.word_count == 1 then
        score = score + 1
    end

    if profile.starts_with_word then
        score = score + 1
    end

    if not profile.starts_with_closer
        and not profile.starts_with_code_keyword
        and not profile.ends_with_clause_keyword
        and not profile.has_brace
        and not profile.has_semicolon
        and not profile.has_assignment
        and not profile.has_compare
        and not profile.has_logic
        and not profile.has_member_access
        and not profile.has_call_parens
    then
        score = score + 3
    end

    if profile.punctuation_count <= 1 then
        score = score + 1
    end

    return score
end

local function score_neighbor_row(next_row, inherited_schema)
    if next_row == nil or next_row.kind == BLOCK_BLANK then
        return 0, 0
    end

    if next_row.kind == inherited_schema.kind then
        return 4, 0
    end

    if next_row.kind ~= BLOCK_TEXT then
        return 0, 1
    end

    local next_profile = next_row.text_profile
    local continuation_score = 0
    local code_score = 0

    local next_code_score = score_code_profile(next_profile)
    if next_code_score >= 4 then
        code_score = code_score + 2
    end

    if score_continuation_profile(next_profile) >= 4 then
        continuation_score = continuation_score + 1
    end

    return continuation_score, code_score
end

is_context_passthrough_row = function(row)
    if row == nil or row.kind ~= BLOCK_TEXT then
        return false
    end

    local continuation_score = score_continuation_profile(row.text_profile)
    local code_score = score_code_profile(row.text_profile)

    return continuation_score >= code_score + 2
end

local function should_inherit_schema(row, inherited_schema, next_row)
    if inherited_schema == nil or row.kind ~= BLOCK_TEXT then
        return false
    end

    local profile = row.text_profile
    local continuation_score = score_continuation_profile(profile)
    local code_score = score_code_profile(profile)
    local neighbor_continuation, neighbor_code = score_neighbor_row(next_row, inherited_schema)
    continuation_score = continuation_score + neighbor_continuation
    code_score = code_score + neighbor_code

    if inherited_schema.kind == BLOCK_COMMENT then
        if profile.starts_with_code_keyword or profile.ends_with_clause_keyword or profile.has_call_parens then
            return false
        end

        if next_row ~= nil and next_row.kind == BLOCK_TEXT then
            local next_profile = next_row.text_profile
            if next_profile.starts_with_code_keyword or next_profile.ends_with_clause_keyword then
                return false
            end
        end

        return continuation_score >= 4 and continuation_score >= code_score + 2
    end

    return continuation_score >= 2 and continuation_score >= code_score
end

local function first_nonblank_row(rows, start_index)
    for i = start_index, #rows do
        if rows[i].kind ~= BLOCK_BLANK then
            return rows[i]
        end
    end

    return nil
end

local function segment_selection(rows, inherited_schema, next_row)
    local segments = {}
    local current_block

    for index = 1, #rows do
        local row = rows[index]

        if row.kind == BLOCK_BLANK then
            flush_block(segments, current_block)
            current_block = nil
            segments[#segments + 1] = { kind = BLOCK_BLANK }
        elseif row.kind ~= BLOCK_TEXT then
            flush_block(segments, current_block)
            current_block = build_block(row.kind, row.first_prefix, row.continuation_prefix)
            append_words(current_block.words, row.body_text)
        else
            if current_block == nil then
                if index == 1 and should_inherit_schema(row, inherited_schema, next_row) then
                    current_block = build_block(
                        inherited_schema.kind,
                        inherited_schema.first_prefix,
                        inherited_schema.continuation_prefix
                    )
                else
                    current_block = build_block(BLOCK_PLAIN, row.first_prefix, row.continuation_prefix)
                end
            end

            append_words(current_block.words, row.body_text)
        end
    end

    flush_block(segments, current_block)

    return segments
end

local function emit_block(block, max_width)
    if block.kind == BLOCK_BLANK then
        return { "" }
    end

    local emitted = {}
    local line = block.first_prefix
    local line_prefix_width = display_width(block.first_prefix)
    local continuation_prefix_width = display_width(block.continuation_prefix)
    local active_prefix_width = line_prefix_width
    local line_width = line_prefix_width

    if #block.words == 0 then
        emitted[1] = line:gsub("%s+$", "")
        return emitted
    end

    for i = 1, #block.words do
        local word = block.words[i]
        local separator = line_width > active_prefix_width and " " or ""
        local candidate = line .. separator .. word
        local candidate_width = display_width(candidate)

        if line_width > active_prefix_width and candidate_width > max_width then
            emitted[#emitted + 1] = line
            line = block.continuation_prefix .. word
            active_prefix_width = continuation_prefix_width
            line_width = display_width(line)
        else
            line = candidate
            line_width = candidate_width
        end
    end

    emitted[#emitted + 1] = line

    return emitted
end

local function emit_segments(segments, max_width)
    local emitted = {}

    for i = 1, #segments do
        local block_lines = emit_block(segments[i], max_width)

        for j = 1, #block_lines do
            emitted[#emitted + 1] = block_lines[j]
        end
    end

    return emitted
end

local function reflow_selected_lines(before_lines, selected_lines, after_lines, max_width)
    local before_rows = parse_lines(before_lines)
    local selected_rows = parse_lines(selected_lines)
    local after_rows = parse_lines(after_lines)
    local inherited_schema = derive_inherited_schema(before_rows)
    local next_row = first_nonblank_row(selected_rows, 2) or first_nonblank_row(after_rows, 1)
    local segments = segment_selection(selected_rows, inherited_schema, next_row)

    return emit_segments(segments, max_width)
end

local function collect_context(bufnr, start_line, end_line)
    local current_config = config.get()
    local context_scan_limit = current_config.context_scan_limit or 0
    local before_start = math.max(start_line - context_scan_limit, 0)
    local after_end = math.min(end_line + context_scan_limit + 1, api.nvim_buf_line_count(bufnr))

    local before_lines = api.nvim_buf_get_lines(bufnr, before_start, start_line, false)
    local selected_lines = api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
    local after_lines = api.nvim_buf_get_lines(bufnr, end_line + 1, after_end, false)

    return before_lines, selected_lines, after_lines
end

local function build_reflow_lines(bufnr, start_line, end_line, max_width)
    local before_lines, selected_lines, after_lines = collect_context(bufnr, start_line, end_line)
    return reflow_selected_lines(before_lines, selected_lines, after_lines, max_width)
end

local function apply_transform(bufnr, start_line, end_line, new_lines, cursor_line, cursor_col)
    api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, new_lines)
    restore_cursor(cursor_line, cursor_col)
end

local function resolve_max_width(bufnr, explicit_width)
    if type(explicit_width) == "number" and explicit_width > 0 then
        return explicit_width
    end

    local current_config = config.get()
    if current_config.use_textwidth ~= false then
        local textwidth = vim.bo[bufnr].textwidth
        if type(textwidth) == "number" and textwidth > 0 then
            return textwidth
        end
    end

    return current_config.max_width
end

local function parse_command_width(args)
    if type(args) ~= "string" or args == "" then
        return nil
    end

    local width = tonumber(args)
    if width == nil or width < 1 then
        error("Wrappin width must be a positive integer")
    end

    return math.floor(width)
end

local function apply_formatexpr()
    vim.o.formatexpr = "v:lua.require'wrappin'.formatexpr()"
end

local function run(opts)
    opts = opts or {}

    local bufnr = opts.bufnr or 0
    local start_line, end_line = normalize_range(opts.start_line, opts.end_line)
    local max_width = resolve_max_width(bufnr, opts.max_width)

    if start_line == nil or end_line == nil then
        start_line, end_line = get_mark_range()
    end

    if start_line == nil or end_line == nil then
        return
    end

    local original_lines = api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
    if #original_lines == 0 then
        return
    end

    local extmark_id, snapshot = state.find_restorable_snapshot(bufnr, start_line, end_line)
    if snapshot ~= nil then
        state.drop_snapshot(bufnr, extmark_id)
        apply_transform(bufnr, start_line, end_line, snapshot.original_lines, opts.cursor_line, opts.cursor_col)
        return
    end

    local new_lines = build_reflow_lines(bufnr, start_line, end_line, max_width)

    if vim.deep_equal(original_lines, new_lines) then
        restore_cursor(opts.cursor_line, opts.cursor_col)
        return
    end

    state.invalidate_overlapping_snapshots(bufnr, start_line, end_line)
    apply_transform(bufnr, start_line, end_line, new_lines, opts.cursor_line, opts.cursor_col)
    state.store_snapshot(bufnr, start_line, original_lines, new_lines)
end

function M.setup(opts)
    local current_config = config.setup(opts)

    if current_config.set_formatexpr then
        apply_formatexpr()
    end

    return M
end

function M.reflow_lines(lines, opts)
    opts = opts or {}

    local max_width = opts.max_width or config.get().max_width
    local before_lines = opts.before_lines or {}
    local after_lines = opts.after_lines or {}

    return reflow_selected_lines(before_lines, lines or {}, after_lines, max_width)
end

function M.wrap(opts)
    return run(opts)
end

function M.wrap_current_line(opts)
    local cursor = api.nvim_win_get_cursor(0)
    local line = cursor[1]
    local current_opts = vim.tbl_extend("force", opts or {}, {
        start_line = line - 1,
        end_line = line - 1,
        cursor_line = line,
        cursor_col = 0,
    })

    return run(current_opts)
end

function M.wrap_visual(opts)
    local start_line, end_line = get_live_visual_range()
    if start_line == nil or end_line == nil then
        return run(opts)
    end

    local scheduled_opts = vim.tbl_extend("force", opts or {}, {
        start_line = start_line,
        end_line = end_line,
        cursor_line = start_line + 1,
        cursor_col = 0,
    })

    exit_visual_mode()

    vim.schedule(function()
        run(scheduled_opts)
    end)
end

function M.command(command_opts)
    local opts = {}

    if command_opts ~= nil then
        opts.max_width = parse_command_width(command_opts.args)

        if command_opts.range and command_opts.range > 0 then
            opts.start_line = command_opts.line1 - 1
            opts.end_line = command_opts.line2 - 1
            opts.cursor_line = command_opts.line1
            opts.cursor_col = 0
        end
    end

    if opts.start_line == nil or opts.end_line == nil then
        return M.wrap_current_line(opts)
    end

    return run(opts)
end

function M.formatexpr()
    if vim.tbl_contains({ "i", "R", "ic", "ix" }, vim.fn.mode()) then
        return 1
    end

    local start_line = vim.v.lnum
    local end_line = start_line + vim.v.count - 1
    if start_line <= 0 or end_line < start_line then
        return 0
    end

    local bufnr = api.nvim_get_current_buf()
    end_line = math.min(end_line, api.nvim_buf_line_count(bufnr))

    run({
        bufnr = bufnr,
        start_line = start_line - 1,
        end_line = end_line - 1,
        cursor_line = start_line,
        cursor_col = 0,
    })

    return 0
end

function M._reset_for_tests()
    config.reset_for_tests()
    state.reset_for_tests()
end

M.run = M.wrap
M.run_visual_selection = M.wrap_visual
M.Wrappin = M.wrap_visual

state.ensure_cleanup_autocmd()

return M
