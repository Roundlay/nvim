local table_unpack = table.unpack or unpack

local original_autocmd = vim.api.nvim_create_autocmd
local original_user_command = vim.api.nvim_create_user_command
local original_keymap_set = vim.keymap.set

local perf_api = nil
local installed = false

local wrappers_by_original = setmetatable({}, { __mode = "k" })
local is_wrapper = setmetatable({}, { __mode = "k" })

local function join_items(items)
    if type(items) == "string" then
        return items
    end
    if type(items) ~= "table" then
        return tostring(items)
    end
    local out = {}
    for i = 1, #items do
        out[#out + 1] = tostring(items[i])
    end
    return table.concat(out, "|")
end

local function wrap_callback(event_type, source, fn)
    if type(fn) ~= "function" then
        return fn
    end
    if is_wrapper[fn] then
        return fn
    end
    local existing = wrappers_by_original[fn]
    if existing then
        return existing
    end
    local function wrapped(...)
        if not perf_api or not perf_api.is_enabled() then
            return fn(...)
        end
        local t0 = perf_api.now()
        local call_results = { pcall(fn, ...) }
        local ok = table.remove(call_results, 1)
        local duration = perf_api.now() - t0
        perf_api.log(event_type, source, t0, duration, ok and 0 or 1)
        if not ok then
            error(call_results[1])
        end
        return table_unpack(call_results)
    end
    wrappers_by_original[fn] = wrapped
    is_wrapper[wrapped] = true
    return wrapped
end

local function format_autocmd_source(events, opts)
    local event_name = join_items(events)
    local pattern = "*"
    if opts then
        local pat = opts.pattern
        if type(pat) == "string" then
            pattern = pat
        elseif type(pat) == "table" then
            pattern = join_items(pat)
        end
    end
    local group = (opts and opts.group) or "global"
    return event_name .. ":" .. tostring(pattern) .. ":" .. tostring(group)
end

local function format_keymap_source(mode, lhs, opts)
    local mode_label = join_items(mode)
    local desc = ""
    if opts and opts.desc and opts.desc ~= "" then
        desc = ":" .. opts.desc
    end
    return mode_label .. ":" .. tostring(lhs) .. desc
end

local function install_autocmd_wrapper()
    vim.api.nvim_create_autocmd = function(events, opts)
        if opts and type(opts.callback) == "function" then
            local source = format_autocmd_source(events, opts)
            opts.callback = wrap_callback("autocmd", source, opts.callback)
        end
        return original_autocmd(events, opts)
    end
end

local function install_user_command_wrapper()
    vim.api.nvim_create_user_command = function(name, command, opts)
        if type(command) == "function" then
            command = wrap_callback("user_cmd", tostring(name), command)
        end
        return original_user_command(name, command, opts)
    end
end

local function install_keymap_wrapper()
    vim.keymap.set = function(mode, lhs, rhs, opts)
        if type(rhs) == "function" then
            local source = format_keymap_source(mode, lhs, opts)
            rhs = wrap_callback("keymap", source, rhs)
        end
        return original_keymap_set(mode, lhs, rhs, opts)
    end
end

local M = {}

function M.attach(perf)
    if installed then
        return
    end
    perf_api = perf
    install_autocmd_wrapper()
    install_user_command_wrapper()
    install_keymap_wrapper()
    installed = true
end

return M
