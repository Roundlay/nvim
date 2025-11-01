local uv = vim.loop

local table_new = table.new or function()
    return {}
end

local state = nil

local function mkdir_p(path)
    if not path or path == "" then
        return true
    end
    local stat = uv.fs_stat(path)
    if stat then
        return stat.type == "directory"
    end
    local parent = vim.fs.dirname(path)
    if parent and parent ~= path then
        local ok_parent, parent_err = mkdir_p(parent)
        if not ok_parent then
            return false, parent_err
        end
    end
    local ok, err = uv.fs_mkdir(path, 448)
    if not ok and err and not err:find("exist", 1, true) then
        return false, err
    end
    return true
end

local function ensure_state()
    if state then
        return true
    end
    return false, "perf collector not configured"
end

local function intern_string(pool, reverse, value)
    if not value or value == "" then
        return 0
    end
    local id = pool[value]
    if id then
        return id
    end
    id = #reverse + 1
    pool[value] = id
    reverse[id] = value
    return id
end

local function realise_string(reverse, id)
    if id == 0 then
        return ""
    end
    return reverse[id] or ""
end

local M = {}

function M.setup(opts)
    local capacity = (opts and opts.capacity) or 4096
    if capacity < 1 then
        capacity = 1024
    end
    local log_path = (opts and opts.path) or (vim.fn.stdpath("state") .. "/perf-trace.log")
    local log_dir = vim.fs.dirname(log_path)
    local ok_dir, dir_err = mkdir_p(log_dir)
    if not ok_dir then
        return false, dir_err or ("failed to create perf log directory: " .. log_dir)
    end
    state = {
        capacity = capacity,
        size = 0,
        path = log_path,
        type_ids = table_new(capacity, 0),
        source_ids = table_new(capacity, 0),
        start_ns = table_new(capacity, 0),
        duration_ns = table_new(capacity, 0),
        flags = table_new(capacity, 0),
        extra_ids = table_new(capacity, 0),
        pool = {},
        reverse = {},
    }
    state.reverse[0] = ""
    return true
end

function M.is_ready()
    return state ~= nil
end

function M.reset()
    if not state then
        return
    end
    state.size = 0
end

local function write_file(payload)
    local fd, open_err = uv.fs_open(state.path, "a", 420)
    if not fd then
        return false, open_err
    end
    local ok, write_err = uv.fs_write(fd, payload, -1)
    uv.fs_close(fd)
    if not ok then
        return false, write_err
    end
    return true
end

function M.flush()
    local ok_state, state_err = ensure_state()
    if not ok_state then
        return false, state_err
    end
    if state.size == 0 then
        return true
    end
    local out = table_new(state.size, 0)
    for i = 1, state.size do
        local line = table.concat({
            tostring(state.start_ns[i]),
            tostring(state.duration_ns[i]),
            realise_string(state.reverse, state.type_ids[i]),
            realise_string(state.reverse, state.source_ids[i]),
            tostring(state.flags[i]),
            realise_string(state.reverse, state.extra_ids[i]),
        }, ",")
        out[i] = line .. "\n"
    end
    local payload = table.concat(out)
    local ok_write, write_err = write_file(payload)
    if not ok_write then
        return false, write_err
    end
    state.size = 0
    return true
end

function M.push(event_type, source, start_ns, duration_ns, flags, extra)
    local ok_state, state_err = ensure_state()
    if not ok_state then
        return false, state_err
    end
    if state.size >= state.capacity then
        local ok_flush, flush_err = M.flush()
        if not ok_flush then
            return false, flush_err
        end
    end
    local idx = state.size + 1
    state.type_ids[idx] = intern_string(state.pool, state.reverse, event_type)
    state.source_ids[idx] = intern_string(state.pool, state.reverse, source)
    state.start_ns[idx] = start_ns or 0
    state.duration_ns[idx] = duration_ns or 0
    state.flags[idx] = flags or 0
    state.extra_ids[idx] = intern_string(state.pool, state.reverse, extra)
    state.size = idx
    return true
end

function M.path()
    if not state then
        return nil
    end
    return state.path
end

function M.capacity()
    if not state then
        return 0
    end
    return state.capacity
end

function M.size()
    if not state then
        return 0
    end
    return state.size
end

return M
