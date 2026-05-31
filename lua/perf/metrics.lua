local uv = vim.loop

local metrics_state = {
    enabled = false,
    total_events = 0,
    total_errors = 0,
    event_index = {},
    event_keys = {},
    event_counts = {},
    event_totals = {},
    event_max = {},
    event_errors = {},
    event_samples = {},
    event_top = {},
    type_totals = {},
    plugin_totals = {},
    module_totals = {},
    summary_path = nil,
}

local function get_event_index(event_type, source)
    local key = event_type .. "\0" .. source
    local idx = metrics_state.event_index[key]
    if idx then
        return idx
    end
    idx = #metrics_state.event_keys + 1
    metrics_state.event_index[key] = idx
    metrics_state.event_keys[idx] = { event_type, source }
    metrics_state.event_counts[idx] = 0
    metrics_state.event_totals[idx] = 0
    metrics_state.event_max[idx] = 0
    metrics_state.event_errors[idx] = 0
    metrics_state.event_samples[idx] = {}
    metrics_state.event_top[idx] = {}
    return idx
end

local function insert_top_sample(top, duration_ns, extra)
    if not extra or extra == "" then
        return
    end
    local entry = { duration = duration_ns, extra = extra }
    local inserted = false
    for i = 1, #top do
        if duration_ns > top[i].duration then
            table.insert(top, i, entry)
            inserted = true
            break
        end
    end
    if not inserted then
        top[#top + 1] = entry
    end
    if #top > 5 then
        top[#top] = nil
    end
end

local function percentile(samples, pct)
    if #samples == 0 then
        return 0
    end
    table.sort(samples)
    local rank = math.ceil(#samples * pct)
    if rank < 1 then
        rank = 1
    elseif rank > #samples then
        rank = #samples
    end
    return samples[rank]
end

local function ensure_directory(path)
    local dir = vim.fs.dirname(path)
    if not dir or dir == "" then
        return true
    end
    local stat = uv.fs_stat(dir)
    if stat and stat.type == "directory" then
        return true
    end
    local parent = vim.fs.dirname(dir)
    if parent and parent ~= dir then
        ensure_directory(dir)
    end
    local ok, err = uv.fs_mkdir(dir, 448)
    if not ok and err and not err:find("exist", 1, true) then
        return false, err
    end
    return true
end

local M = {}

function M.configure(opts)
    metrics_state.summary_path = opts and opts.summary_path or nil
    metrics_state.enabled = true
end

function M.reset()
    metrics_state.total_events = 0
    metrics_state.total_errors = 0
    metrics_state.event_index = {}
    metrics_state.event_keys = {}
    metrics_state.event_counts = {}
    metrics_state.event_totals = {}
    metrics_state.event_max = {}
    metrics_state.event_errors = {}
    metrics_state.event_samples = {}
    metrics_state.event_top = {}
    metrics_state.type_totals = {}
    metrics_state.plugin_totals = {}
    metrics_state.module_totals = {}
end

local function update_plugin_totals(event_type, source, duration_ns)
    if not event_type or not source then
        return
    end
    if not event_type:find("^lazy_", 1, true) then
        return
    end
    local entry = metrics_state.plugin_totals[source]
    if not entry then
        entry = { total = 0, count = 0 }
        metrics_state.plugin_totals[source] = entry
    end
    entry.total = entry.total + duration_ns
    entry.count = entry.count + 1
end

local function update_module_totals(event_type, source, duration_ns)
    if event_type ~= "module_lua" then
        return
    end
    local entry = metrics_state.module_totals[source]
    if not entry then
        entry = { total = 0, count = 0 }
        metrics_state.module_totals[source] = entry
    end
    entry.total = entry.total + duration_ns
    entry.count = entry.count + 1
end

function M.push(event_type, source, duration_ns, flags, extra)
    if not metrics_state.enabled then
        return
    end
    metrics_state.total_events = metrics_state.total_events + 1
    if flags and flags ~= 0 then
        metrics_state.total_errors = metrics_state.total_errors + 1
    end
    local idx = get_event_index(event_type, source or "")
    metrics_state.event_counts[idx] = metrics_state.event_counts[idx] + 1
    metrics_state.event_totals[idx] = metrics_state.event_totals[idx] + duration_ns
    if duration_ns > metrics_state.event_max[idx] then
        metrics_state.event_max[idx] = duration_ns
    end
    if flags and flags ~= 0 then
        metrics_state.event_errors[idx] = metrics_state.event_errors[idx] + 1
    end
    local samples = metrics_state.event_samples[idx]
    samples[#samples + 1] = duration_ns
    insert_top_sample(metrics_state.event_top[idx], duration_ns, extra)

    local type_entry = metrics_state.type_totals[event_type]
    if not type_entry then
        type_entry = { total = 0, count = 0 }
        metrics_state.type_totals[event_type] = type_entry
    end
    type_entry.total = type_entry.total + duration_ns
    type_entry.count = type_entry.count + 1

    update_plugin_totals(event_type, source or "", duration_ns)
    update_module_totals(event_type, source or "", duration_ns)
end

local function build_event_source_rows()
    local rows = {}
    for i = 1, #metrics_state.event_keys do
        local key = metrics_state.event_keys[i]
        local samples = metrics_state.event_samples[i]
        local total_ns = metrics_state.event_totals[i]
        local count = metrics_state.event_counts[i]
        local avg_ns = count > 0 and (total_ns / count) or 0
        local p95_ns = percentile(samples, 0.95)
        rows[#rows + 1] = {
            event = key[1],
            source = key[2],
            count = count,
            total_ns = total_ns,
            avg_ns = avg_ns,
            p95_ns = p95_ns,
            max_ns = metrics_state.event_max[i],
            errors = metrics_state.event_errors[i],
            top = metrics_state.event_top[i],
        }
    end
    table.sort(rows, function(a, b)
        if a.total_ns == b.total_ns then
            return a.count > b.count
        end
        return a.total_ns > b.total_ns
    end)
    return rows
end

local function build_totals_rows(map, key_name)
    local rows = {}
    for key, data in pairs(map) do
        rows[#rows + 1] = {
            [key_name] = key,
            total_ns = data.total,
            count = data.count,
            avg_ns = data.count > 0 and (data.total / data.count) or 0,
        }
    end
    table.sort(rows, function(a, b)
        if a.total_ns == b.total_ns then
            return a.count > b.count
        end
        return a.total_ns > b.total_ns
    end)
    return rows
end

local function build_event_type_rows()
    local rows = {}
    for event_type, data in pairs(metrics_state.type_totals) do
        rows[#rows + 1] = {
            event = event_type,
            total_ns = data.total,
            count = data.count,
            avg_ns = data.count > 0 and (data.total / data.count) or 0,
        }
    end
    table.sort(rows, function(a, b)
        if a.total_ns == b.total_ns then
            return a.count > b.count
        end
        return a.total_ns > b.total_ns
    end)
    return rows
end

function M.write_summary()
    if not metrics_state.summary_path then
        return true
    end
    local ok_dir, dir_err = ensure_directory(metrics_state.summary_path)
    if not ok_dir then
        return false, dir_err
    end
    local payload = {
        meta = {
            generated_ns = vim.loop.hrtime(),
            events = metrics_state.total_events,
            errors = metrics_state.total_errors,
        },
        event_sources = build_event_source_rows(),
        event_totals = build_event_type_rows(),
        plugin_totals = build_totals_rows(metrics_state.plugin_totals, "plugin"),
        module_totals = build_totals_rows(metrics_state.module_totals, "module"),
    }
    local encoded = vim.json and vim.json.encode(payload) or vim.fn.json_encode(payload)
    local fd, err = uv.fs_open(metrics_state.summary_path, "w", 420)
    if not fd then
        return false, err
    end
    uv.fs_write(fd, encoded, -1)
    uv.fs_close(fd)
    return true
end

return M
