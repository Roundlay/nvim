local table_unpack = table.unpack or unpack

local original_autocmd = vim.api.nvim_create_autocmd
local original_user_command = vim.api.nvim_create_user_command
local original_keymap_set = vim.keymap.set

local perf_api = nil
local installed = false

local wrapper_marker = setmetatable({}, { __mode = "k" })
local metadata_tables = setmetatable({}, { __mode = "k" })
local metadata_strings = setmetatable({}, { __mode = "k" })

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

local function normalize_meta_value(value)
    if value == nil then
        return nil
    end
    if type(value) == "boolean" then
        return value and 1 or 0
    end
    return value
end

local function format_meta(meta)
    local keys = {}
    for key in pairs(meta) do
        keys[#keys + 1] = key
    end
    if #keys == 0 then
        return ""
    end
    table.sort(keys)
    local out = {}
    for i = 1, #keys do
        local key = keys[i]
        local value = normalize_meta_value(meta[key])
        if value ~= nil then
            local str = tostring(value)
            str = str:gsub("[,|=]", "_")
            out[#out + 1] = key .. "=" .. str
        end
    end
    return table.concat(out, "|")
end

local function refresh_metadata(wrapper)
    local meta = metadata_tables[wrapper]
    if not meta then
        metadata_strings[wrapper] = ""
        return
    end
    metadata_strings[wrapper] = format_meta(meta)
end

local function wrap_callback(event_type, source, fn, meta)
    if type(fn) ~= "function" then
        return fn, meta
    end
    if wrapper_marker[fn] then
        return fn, metadata_tables[fn]
    end
    meta = meta or {}
    local info = debug.getinfo(fn, "Sl")
    if info then
        if not meta.src and info.short_src then
            meta.src = info.short_src
        end
        if not meta.line and info.linedefined and info.linedefined >= 0 then
            meta.line = info.linedefined
        end
    end
    local wrapper
    wrapper = function(...)
        if not perf_api or not perf_api.is_enabled() then
            return fn(...)
        end
        local t0 = perf_api.now()
        local call_results = { pcall(fn, ...) }
        local ok = table.remove(call_results, 1)
        local duration = perf_api.now() - t0
        local extra = metadata_strings[wrapper]
        perf_api.log(event_type, source, t0, duration, ok and 0 or 1, extra)
        if not ok then
            error(call_results[1])
        end
        return table_unpack(call_results)
    end
    metadata_tables[wrapper] = meta
    refresh_metadata(wrapper)
    wrapper_marker[wrapper] = true
    return wrapper, meta
end

local function update_wrapper_metadata(wrapper, updates)
    if not wrapper then
        return
    end
    local meta = metadata_tables[wrapper]
    if not meta then
        if type(updates) == "table" then
            metadata_tables[wrapper] = updates
        end
        refresh_metadata(wrapper)
        return
    end
    if type(updates) == "table" then
        for key, value in pairs(updates) do
            meta[key] = value
        end
    end
    refresh_metadata(wrapper)
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

local function build_autocmd_meta(events, opts)
    local meta = {
        event = join_items(events),
        pattern = "*",
        once = opts and opts.once or false,
    }
    if opts then
        if opts.pattern then
            if type(opts.pattern) == "string" then
                meta.pattern = opts.pattern
            elseif type(opts.pattern) == "table" then
                meta.pattern = join_items(opts.pattern)
            end
        end
        if opts.group then
            meta.group = opts.group
        end
        if opts.buffer then
            meta.buffer = opts.buffer
        end
    end
    return meta
end

local function install_autocmd_wrapper()
    vim.api.nvim_create_autocmd = function(events, opts)
        if opts and type(opts.callback) == "function" then
            local source = format_autocmd_source(events, opts)
            local meta = build_autocmd_meta(events, opts)
            local callback, meta_ref = wrap_callback("autocmd", source, opts.callback, meta)
            opts.callback = callback
            local result = original_autocmd(events, opts)
            local ids = {}
            if type(result) == "number" then
                ids[1] = result
            elseif type(result) == "table" then
                for i = 1, #result do
                    if type(result[i]) == "number" then
                        ids[#ids + 1] = result[i]
                    end
                end
            end
            if #ids > 0 then
                meta_ref.id = table.concat(ids, "|")
                if not meta_ref.group or type(meta_ref.group) ~= "string" then
                    local ok, info = pcall(vim.api.nvim_get_autocmds, { id = ids[1] })
                    if ok and info[1] and info[1].group_name and info[1].group_name ~= "" then
                        meta_ref.group = info[1].group_name
                    end
                end
            end
            update_wrapper_metadata(callback)
            return result
        end
        return original_autocmd(events, opts)
    end
end

local function format_keymap_source(mode, lhs, opts)
    local mode_label = join_items(mode)
    local desc = ""
    if opts and opts.desc and opts.desc ~= "" then
        desc = ":" .. opts.desc
    end
    return mode_label .. ":" .. tostring(lhs) .. desc
end

local function build_keymap_meta(mode, lhs, opts)
    local meta = {
        mode = join_items(mode),
        lhs = lhs,
    }
    if opts then
        if opts.desc then
            meta.desc = opts.desc
        end
        if opts.buffer then
            meta.buffer = opts.buffer
        end
        if opts.expr ~= nil then
            meta.expr = opts.expr
        end
        if opts.silent ~= nil then
            meta.silent = opts.silent
        end
        if opts.remap ~= nil then
            meta.remap = opts.remap
        end
    end
    return meta
end

local function install_user_command_wrapper()
    vim.api.nvim_create_user_command = function(name, command, opts)
        if type(command) == "function" then
            local meta = {
                name = tostring(name),
            }
            if opts then
                if opts.nargs then
                    meta.nargs = opts.nargs
                end
                if opts.range then
                    meta.range = opts.range
                end
                if opts.bang ~= nil then
                    meta.bang = opts.bang
                end
                if opts.complete then
                    meta.complete = opts.complete
                end
            end
            local wrapped = wrap_callback("user_cmd", tostring(name), command, meta)
            command = wrapped
        end
        return original_user_command(name, command, opts)
    end
end

local function install_keymap_wrapper()
    vim.keymap.set = function(mode, lhs, rhs, opts)
        if type(rhs) == "function" then
            local source = format_keymap_source(mode, lhs, opts)
            local meta = build_keymap_meta(mode, lhs, opts)
            local wrapped = wrap_callback("keymap", source, rhs, meta)
            rhs = wrapped
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
