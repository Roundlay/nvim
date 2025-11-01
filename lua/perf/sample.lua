local uv = vim.loop

local perf_api = nil
local timer = nil
local interval_ms = 5000

local function count_table_entries(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

local function collect_sample()
    if not perf_api or not perf_api.is_enabled() then
        return
    end
    local t0 = perf_api.now()
    local gc_kb = collectgarbage("count")
    local buf_count = #vim.api.nvim_list_bufs()
    local win_count = #vim.api.nvim_list_wins()
    local clients = 0
    local ok, lsp = pcall(vim.lsp.get_clients, {})
    if ok and type(lsp) == "table" then
        clients = #lsp
    end
    local ts_count = 0
    local has_ts, ts = pcall(require, "vim.treesitter.highlighter")
    if has_ts and ts and ts.active then
        ts_count = count_table_entries(ts.active)
    end
    local extra = table.concat({
        string.format("gc=%.2f", gc_kb),
        "buf=" .. buf_count,
        "win=" .. win_count,
        "lsp=" .. clients,
        "ts=" .. ts_count,
    }, ";")
    perf_api.log("sample", "runtime", t0, 0, 0, extra)
end

local M = {}

function M.attach(perf)
    perf_api = perf
    if not timer then
        timer = uv.new_timer()
    end
end

function M.start()
    if not timer then
        timer = uv.new_timer()
    end
    if timer:is_active() then
        return
    end
    timer:start(interval_ms, interval_ms, vim.schedule_wrap(collect_sample))
end

function M.stop()
    if timer and timer:is_active() then
        timer:stop()
    end
end

function M.sample_now()
    collect_sample()
end

return M
