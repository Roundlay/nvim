local collector = require("perf.collector")
local runtime = require("perf.runtime")
local loader = require("perf.loader")
local sampler = require("perf.sample")

local uv = vim.loop

local M = {}

local config = {
    capacity = 4096,
    path = vim.fn.stdpath("state") .. "/perf-trace.log",
}

local enabled = false
local configured = false
local commands_defined = false
local augroup_id = nil

local function notify_err(message)
    if vim.notify then
        vim.notify(message, vim.log.levels.ERROR, { title = "PerfTrace" })
    else
        vim.api.nvim_echo({ { message, "ErrorMsg" } }, false, {})
    end
end

local function ensure_setup()
    if configured and collector.is_ready() then
        return true
    end
    local ok, err = collector.setup({
        capacity = config.capacity,
        path = config.path,
    })
    if not ok then
        notify_err("perf collector setup failed: " .. (err or "unknown error"))
        return false
    end
    configured = true
    return true
end

local function ensure_augroup()
    if augroup_id then
        return
    end
    augroup_id = vim.api.nvim_create_augroup("PerfTrace", { clear = true })
    vim.api.nvim_create_autocmd({ "VimLeavePre", "ExitPre" }, {
        group = augroup_id,
        callback = function()
            collector.flush()
        end,
    })
end

local function define_commands()
    if commands_defined then
        return
    end
    commands_defined = true
    vim.api.nvim_create_user_command("PerfTraceEnable", function()
        local ok = M.enable()
        if not ok then
            notify_err("PerfTraceEnable failed")
        end
    end, {})
    vim.api.nvim_create_user_command("PerfTraceDisable", function()
        M.disable()
    end, {})
    vim.api.nvim_create_user_command("PerfTraceFlush", function()
        local ok, err = collector.flush()
        if not ok then
            notify_err("PerfTraceFlush failed: " .. (err or "unknown error"))
        end
    end, {})
    vim.api.nvim_create_user_command("PerfReport", function(cmd_opts)
        local ok_flush, flush_err = collector.flush()
        if not ok_flush then
            notify_err("PerfReport flush failed: " .. (flush_err or "unknown error"))
            return
        end
        local limit = tonumber(cmd_opts.args)
        local ok_report, err = require("perf.report").show({ limit = limit })
        if not ok_report and err then
            notify_err("PerfReport failed: " .. err)
        end
    end, { nargs = "?" })
end

function M.configure(opts)
    if not opts then
        return
    end
    if type(opts.capacity) == "number" and opts.capacity > 0 then
        config.capacity = math.floor(opts.capacity)
    end
    if type(opts.path) == "string" and opts.path ~= "" then
        config.path = opts.path
    end
end

function M.enable()
    if enabled then
        return true
    end
    if not ensure_setup() then
        return false
    end
    ensure_augroup()
    enabled = true
    sampler.start()
    return true
end

function M.disable()
    if not enabled then
        return
    end
    collector.flush()
    enabled = false
    sampler.stop()
end

function M.flush()
    return collector.flush()
end

function M.is_enabled()
    return enabled
end

function M.log(event_type, source, start_ns, duration_ns, flags, extra)
    if not enabled then
        return true
    end
    return collector.push(event_type, source, start_ns, duration_ns, flags, extra)
end

function M.now()
    return uv.hrtime()
end

function M.measure_span(event_type, source, start_ns, stop_ns, flags, extra)
    if not enabled then
        return true
    end
    local duration = (stop_ns or M.now()) - start_ns
    return collector.push(event_type, source, start_ns, duration, flags, extra)
end

function M.time_block(event_type, source, fn, flags, extra)
    if not enabled then
        return fn()
    end
    local t0 = M.now()
    local ok, result = pcall(fn)
    local t1 = M.now()
    collector.push(event_type, source, t0, t1 - t0, ok and (flags or 0) or 1, extra)
    if not ok then
        error(result)
    end
    return result
end

define_commands()

runtime.attach(M)
loader.attach(M)
sampler.attach(M)

local env = vim.env.NVIM_PERF_TRACE
if env == "1" or env == "true" then
    M.enable()
end

return M
