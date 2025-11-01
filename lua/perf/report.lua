local collector = require("perf.collector")

local M = {}

local NANOS_IN_MS = 1e6

local function read_lines(path)
    local file = io.open(path, "r")
    if not file then
        return {}
    end
    local lines = {}
    for line in file:lines() do
        lines[#lines + 1] = line
    end
    file:close()
    return lines
end

local function parse_line(line)
    local start_ns, duration_ns, event_type, source, flags, extra =
        line:match("^([^,]+),([^,]+),([^,]*),([^,]*),([^,]*),(.*)$")
    if not start_ns then
        return nil
    end
    return {
        start_ns = tonumber(start_ns) or 0,
        duration_ns = tonumber(duration_ns) or 0,
        event_type = event_type or "",
        source = source or "",
        flags = tonumber(flags) or 0,
        extra = extra or "",
    }
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

local function aggregate(events)
    local buckets = {}
    for i = 1, #events do
        local evt = events[i]
        local key = evt.event_type .. "\0" .. evt.source
        local bucket = buckets[key]
        if not bucket then
            bucket = {
                event_type = evt.event_type,
                source = evt.source,
                count = 0,
                total_ns = 0,
                max_ns = 0,
                errors = 0,
                samples = {},
            }
            buckets[key] = bucket
        end
        bucket.count = bucket.count + 1
        bucket.total_ns = bucket.total_ns + evt.duration_ns
        if evt.duration_ns > bucket.max_ns then
            bucket.max_ns = evt.duration_ns
        end
        if evt.flags ~= 0 then
            bucket.errors = bucket.errors + 1
        end
        bucket.samples[#bucket.samples + 1] = evt.duration_ns
    end
    local list = {}
    for _, bucket in pairs(buckets) do
        list[#list + 1] = bucket
    end
    table.sort(list, function(a, b)
        if a.total_ns == b.total_ns then
            return a.count > b.count
        end
        return a.total_ns > b.total_ns
    end)
    return list
end

local function format_ms(ns)
    return ns / NANOS_IN_MS
end

local function truncate(text, width)
    if #text <= width then
        return text
    end
    return text:sub(1, width - 3) .. "..."
end

function M.summary(opts)
    opts = opts or {}
    local path = opts.path or collector.path()
    if not path then
        return {}, "perf log path is not available"
    end
    local lines = read_lines(path)
    local events = {}
    for i = 1, #lines do
        local evt = parse_line(lines[i])
        if evt then
            if not opts.event_type or evt.event_type == opts.event_type then
                events[#events + 1] = evt
            end
        end
    end
    local buckets = aggregate(events)
    for i = 1, #buckets do
        local bucket = buckets[i]
        bucket.avg_ns = bucket.count > 0 and (bucket.total_ns / bucket.count) or 0
        bucket.p95_ns = percentile(bucket.samples, 0.95)
    end
    return buckets
end

function M.summary_lines(opts)
    opts = opts or {}
    local limit = opts.limit or 20
    local buckets, err = M.summary(opts)
    if not buckets then
        return nil, err
    end
    local lines = {}
    lines[#lines + 1] = string.format(
        "%-12s  %-48s  %6s  %10s  %8s  %8s  %8s  %4s",
        "TYPE",
        "SOURCE",
        "COUNT",
        "TOTAL_MS",
        "AVG_MS",
        "P95_MS",
        "MAX_MS",
        "ERR"
    )
    local max_items = math.min(limit, #buckets)
    for i = 1, max_items do
        local bucket = buckets[i]
        lines[#lines + 1] = string.format(
            "%-12s  %-48s  %6d  %10.3f  %8.3f  %8.3f  %8.3f  %4d",
            truncate(bucket.event_type, 12),
            truncate(bucket.source, 48),
            bucket.count,
            format_ms(bucket.total_ns),
            format_ms(bucket.avg_ns),
            format_ms(bucket.p95_ns),
            format_ms(bucket.max_ns),
            bucket.errors
        )
    end
    return lines
end

function M.show(opts)
    local lines, err = M.summary_lines(opts)
    if not lines then
        return false, err
    end
    vim.api.nvim_out_write(table.concat(lines, "\n") .. "\n")
    return true
end

return M
