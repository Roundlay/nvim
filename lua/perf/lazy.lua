local perf = require("perf.init")

local M = {}

local table_unpack = table.unpack or unpack

local function is_array(tbl)
    local count = 0
    local max_index = 0
    for k, _ in pairs(tbl) do
        if type(k) ~= "number" then
            return false
        end
        if k > max_index then
            max_index = k
        end
        count = count + 1
    end
    if count == 0 then
        return false
    end
    return max_index == count
end

local function wrap_callable(plugin_name, field_name, fn)
    if type(fn) ~= "function" then
        return fn
    end
    local event_type = "lazy_" .. field_name
    return function(...)
        if not perf.is_enabled() then
            return fn(...)
        end
        local t0 = perf.now()
        local call_results = { pcall(fn, ...) }
        local ok = table.remove(call_results, 1)
        local duration = perf.now() - t0
        perf.log(event_type, plugin_name, t0, duration, ok and 0 or 1)
        if not ok then
            error(call_results[1])
        end
        return table_unpack(call_results)
    end
end

local function wrap_spec(spec, origin)
    if type(spec) ~= "table" then
        return spec
    end
    if spec._perf_wrapped then
        return spec
    end
    local plugin_name = spec.name or spec[1] or origin or "unknown"
    spec._perf_wrapped = true
    spec._perf_plugin_name = plugin_name
    spec.init = wrap_callable(plugin_name, "init", spec.init)
    spec.config = wrap_callable(plugin_name, "config", spec.config)
    spec.build = wrap_callable(plugin_name, "build", spec.build)
    spec.opts = wrap_callable(plugin_name, "opts", spec.opts)
    if spec.dependencies then
        if is_array(spec.dependencies) then
            for i = 1, #spec.dependencies do
                spec.dependencies[i] = wrap_spec(spec.dependencies[i], plugin_name .. "::dep")
            end
        else
            for key, dep in pairs(spec.dependencies) do
                spec.dependencies[key] = wrap_spec(dep, plugin_name .. "::dep")
            end
        end
    end
    return spec
end

function M.instrument(specs, origin)
    if type(specs) ~= "table" then
        return specs
    end
    if type(specs[1]) == "string" or type(specs.name) == "string" then
        return wrap_spec(specs, origin)
    end
    if is_array(specs) then
        for i = 1, #specs do
            specs[i] = wrap_spec(specs[i], origin)
        end
    else
        for key, value in pairs(specs) do
            specs[key] = wrap_spec(value, origin or key)
        end
    end
    return specs
end

return M
