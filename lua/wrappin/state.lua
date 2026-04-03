local api = vim.api

local M = {}

local SNAPSHOT_NAMESPACE = api.nvim_create_namespace("wrappin")

local snapshots_by_buf = {}
local cleanup_registered = false

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

function M.ensure_cleanup_autocmd()
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

function M.invalidate_overlapping_snapshots(bufnr, start_line, end_line)
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

function M.store_snapshot(bufnr, start_line, original_lines, wrapped_lines)
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

function M.find_restorable_snapshot(bufnr, start_line, end_line)
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

function M.drop_snapshot(bufnr, extmark_id)
    drop_snapshot(bufnr, extmark_id)
end

function M.reset_for_tests()
    snapshots_by_buf = {}

    for _, bufnr in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_valid(bufnr) then
            api.nvim_buf_clear_namespace(bufnr, SNAPSHOT_NAMESPACE, 0, -1)
        end
    end
end

return M
