if vim.g.vscode then
    return {}
end

local api = vim.api
local fn = vim.fn

local M = {}

local DEFAULT_MAX_WIDTH = 80
local CONTEXT_SCAN_LIMIT = 8
local SNAPSHOT_NAMESPACE = api.nvim_create_namespace("wrappin")

local BLOCK_BLANK = "blank"
local BLOCK_TEXT = "text"
local BLOCK_PLAIN = "plain"
local BLOCK_COMMENT = "comment"
local BLOCK_BULLET = "bullet"
local BLOCK_ORDERED = "ordered"
local BLOCK_HEADING = "heading"

local snapshots_by_buf = {}
local cleanup_registered = false

local function ensure_cleanup_autocmd()
    if cleanup_registered then
        return
    end

    cleanup_registered = true

    api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
        callback = function(args)
            snapshots_by_buf[args.buf] = nil
        end,
    })
end

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

local function line_signature(lines)
    return table.concat(lines, "\n")
end

local function clone_lines(lines)
    local copy = {}

    for i = 1, #lines do
        copy[i] = lines[i]
    end

    return copy
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

local function parse_row(raw)
    local indent_text = raw:match("^(%s*)") or ""
    local rest = raw:sub(#indent_text + 1)

    if rest == "" then
        return {
            raw = raw,
            kind = BLOCK_BLANK,
            indent_text = indent_text,
            body_text = "",
        }
    end

    local marker_text, marker_spacing, body_text

    marker_text, marker_spacing, body_text = rest:match("^(#+)(%s+)(.*)$")
    if marker_text ~= nil then
        return build_prefixed_row(raw, BLOCK_HEADING, indent_text, marker_text, marker_spacing, body_text)
    end

    marker_text, marker_spacing, body_text = rest:match("^(%d+[.)])(%s+)(.*)$")
    if marker_text ~= nil then
        return build_prefixed_row(raw, BLOCK_ORDERED, indent_text, marker_text, marker_spacing, body_text)
    end

    marker_text, marker_spacing, body_text = rest:match("^([%-%+%*])(%s+)(.*)$")
    if marker_text ~= nil then
        return build_prefixed_row(raw, BLOCK_BULLET, indent_text, marker_text, marker_spacing, body_text)
    end

    marker_text, marker_spacing, body_text = rest:match("^(//+)(%s*)(.*)$")
    if marker_text ~= nil then
        return build_prefixed_row(raw, BLOCK_COMMENT, indent_text, marker_text, marker_spacing, body_text)
    end

    marker_text, marker_spacing, body_text = rest:match("^(%-%-+)(%s*)(.*)$")
    if marker_text ~= nil then
        return build_prefixed_row(raw, BLOCK_COMMENT, indent_text, marker_text, marker_spacing, body_text)
    end

    marker_text, marker_spacing, body_text = rest:match("^(;+)(%s*)(.*)$")
    if marker_text ~= nil then
        return build_prefixed_row(raw, BLOCK_COMMENT, indent_text, marker_text, marker_spacing, body_text)
    end

    return {
        raw = raw,
        kind = BLOCK_TEXT,
        indent_text = indent_text,
        body_text = rest,
        first_prefix = indent_text,
        continuation_prefix = indent_text,
    }
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

local function derive_inherited_schema(before_lines)
    for i = #before_lines, 1, -1 do
        local row = parse_row(before_lines[i])

        if row.kind == BLOCK_BLANK then
            return nil
        end

        if row.kind ~= BLOCK_TEXT then
            return {
                kind = row.kind,
                first_prefix = row.continuation_prefix,
                continuation_prefix = row.continuation_prefix,
            }
        end
    end

    return nil
end

local function segment_selection(lines, inherited_schema)
    local segments = {}
    local current_block

    for index = 1, #lines do
        local row = parse_row(lines[index])

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
                if index == 1 and inherited_schema ~= nil then
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

local function collect_context(bufnr, start_line, end_line)
    local before_start = math.max(start_line - CONTEXT_SCAN_LIMIT, 0)

    local before_lines = api.nvim_buf_get_lines(bufnr, before_start, start_line, false)
    local selected_lines = api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

    return before_lines, selected_lines
end

local function get_snapshot_bucket(bufnr)
    local bucket = snapshots_by_buf[bufnr]

    if bucket == nil then
        bucket = {}
        snapshots_by_buf[bufnr] = bucket
    end

    return bucket
end

local function get_snapshot_mark(bufnr, extmark_id)
    local ok, mark = pcall(api.nvim_buf_get_extmark_by_id, bufnr, SNAPSHOT_NAMESPACE, extmark_id, { details = true })
    if not ok or type(mark) ~= "table" or #mark < 3 then
        return nil
    end

    local details = mark[3] or {}
    if details.invalid then
        return nil
    end

    return {
        start_line = mark[1],
        start_col = mark[2],
        end_line = details.end_row or mark[1],
        end_col = details.end_col or mark[2],
    }
end

local function drop_snapshot(bufnr, extmark_id)
    local bucket = snapshots_by_buf[bufnr]

    if bucket ~= nil then
        bucket[extmark_id] = nil
        if next(bucket) == nil then
            snapshots_by_buf[bufnr] = nil
        end
    end

    if api.nvim_buf_is_valid(bufnr) then
        pcall(api.nvim_buf_del_extmark, bufnr, SNAPSHOT_NAMESPACE, extmark_id)
    end
end

local function ranges_overlap(a_start, a_end, b_start, b_end)
    return a_start <= b_end and b_start <= a_end
end

local function invalidate_overlapping_snapshots(bufnr, start_line, end_line)
    local bucket = snapshots_by_buf[bufnr]

    if bucket == nil then
        return
    end

    local extmark_ids = {}
    local count = 0

    for extmark_id in pairs(bucket) do
        count = count + 1
        extmark_ids[count] = extmark_id
    end

    for i = 1, count do
        local extmark_id = extmark_ids[i]
        local mark = get_snapshot_mark(bufnr, extmark_id)

        if mark == nil then
            drop_snapshot(bufnr, extmark_id)
        elseif ranges_overlap(mark.start_line, mark.end_line, start_line, end_line) then
            drop_snapshot(bufnr, extmark_id)
        end
    end
end

local function store_snapshot(bufnr, start_line, original_lines, wrapped_lines)
    if #wrapped_lines == 0 or vim.deep_equal(original_lines, wrapped_lines) then
        return
    end

    local last_line = wrapped_lines[#wrapped_lines] or ""
    local extmark_id = api.nvim_buf_set_extmark(bufnr, SNAPSHOT_NAMESPACE, start_line, 0, {
        end_row = start_line + #wrapped_lines - 1,
        end_col = #last_line,
        right_gravity = false,
        end_right_gravity = true,
        undo_restore = true,
        invalidate = true,
    })

    local bucket = get_snapshot_bucket(bufnr)
    bucket[extmark_id] = {
        original_lines = clone_lines(original_lines),
        wrapped_lines = clone_lines(wrapped_lines),
        wrapped_signature = line_signature(wrapped_lines),
    }
end

local function find_restorable_snapshot(bufnr, start_line, end_line)
    local bucket = snapshots_by_buf[bufnr]

    if bucket == nil then
        return nil, nil
    end

    local current_lines = api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
    local extmark_ids = {}
    local count = 0

    for extmark_id in pairs(bucket) do
        count = count + 1
        extmark_ids[count] = extmark_id
    end

    for i = 1, count do
        local extmark_id = extmark_ids[i]
        local snapshot = bucket[extmark_id]
        local mark = get_snapshot_mark(bufnr, extmark_id)

        if mark == nil then
            drop_snapshot(bufnr, extmark_id)
        elseif mark.start_line == start_line and mark.end_line == end_line then
            if line_signature(current_lines) == snapshot.wrapped_signature then
                return extmark_id, snapshot
            end

            drop_snapshot(bufnr, extmark_id)
        end
    end

    return nil, nil
end

local function build_reflow_lines(bufnr, start_line, end_line, max_width)
    local before_lines, selected_lines = collect_context(bufnr, start_line, end_line)
    local inherited_schema = derive_inherited_schema(before_lines)
    local segments = segment_selection(selected_lines, inherited_schema)

    return emit_segments(segments, max_width)
end

local function apply_transform(bufnr, start_line, end_line, new_lines, cursor_line, cursor_col)
    api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, new_lines)
    restore_cursor(cursor_line, cursor_col)
end

local function run(opts)
    opts = opts or {}

    local bufnr = opts.bufnr or 0
    local start_line, end_line = normalize_range(opts.start_line, opts.end_line)
    local max_width = opts.max_width or DEFAULT_MAX_WIDTH

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

    local extmark_id, snapshot = find_restorable_snapshot(bufnr, start_line, end_line)
    if snapshot ~= nil then
        drop_snapshot(bufnr, extmark_id)
        apply_transform(bufnr, start_line, end_line, snapshot.original_lines, opts.cursor_line, opts.cursor_col)
        return
    end

    local new_lines = build_reflow_lines(bufnr, start_line, end_line, max_width)

    if vim.deep_equal(original_lines, new_lines) then
        restore_cursor(opts.cursor_line, opts.cursor_col)
        return
    end

    invalidate_overlapping_snapshots(bufnr, start_line, end_line)
    apply_transform(bufnr, start_line, end_line, new_lines, opts.cursor_line, opts.cursor_col)
    store_snapshot(bufnr, start_line, original_lines, new_lines)
end

function M.run(opts)
    return run(opts)
end

function M.run_visual_selection(opts)
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

function M._reset_for_tests()
    snapshots_by_buf = {}

    for _, bufnr in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_valid(bufnr) then
            api.nvim_buf_clear_namespace(bufnr, SNAPSHOT_NAMESPACE, 0, -1)
        end
    end
end

ensure_cleanup_autocmd()

return M
