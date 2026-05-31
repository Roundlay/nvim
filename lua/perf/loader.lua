local table_unpack = table.unpack or unpack

local perf_api = nil
local installed = false

local function wrap_searcher(searcher, event_type)
    if type(searcher) ~= "function" then
        return searcher
    end
    return function(module_name)
        local loader, extra = searcher(module_name)
        if type(loader) ~= "function" then
            return loader, extra
        end
        local function wrapped_loader(...)
            if not perf_api or not perf_api.is_enabled() then
                return loader(...)
            end
            local t0 = perf_api.now()
            local results = { pcall(loader, ...) }
            local ok = table.remove(results, 1)
            local duration = perf_api.now() - t0
            local caller = debug.getinfo(3, "Sl") or debug.getinfo(2, "Sl")
            local extra_meta = ""
            if caller then
                local src = caller.short_src or caller.source or "unknown"
                local line = caller.currentline or caller.linedefined or 0
                src = tostring(src):gsub("[,|=]", "_")
                extra_meta = string.format("caller=%s:%d", src, line)
            end
            perf_api.log(event_type, module_name, t0, duration, ok and 0 or 1, extra_meta)
            if not ok then
                error(results[1])
            end
            return table_unpack(results)
        end
        return wrapped_loader, extra
    end
end

local M = {}

function M.attach(perf)
    if installed then
        return
    end
    perf_api = perf
    if type(package.searchers) == "table" then
        if package.searchers[2] then
            package.searchers[2] = wrap_searcher(package.searchers[2], "module_lua")
        end
        if package.searchers[3] then
            package.searchers[3] = wrap_searcher(package.searchers[3], "module_c")
        end
    elseif type(package.loaders) == "table" then
        if package.loaders[2] then
            package.loaders[2] = wrap_searcher(package.loaders[2], "module_lua")
        end
        if package.loaders[3] then
            package.loaders[3] = wrap_searcher(package.loaders[3], "module_c")
        end
    end
    installed = true
end

return M
