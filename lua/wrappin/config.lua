local M = {}

local defaults = {
    max_width = 80,
    use_textwidth = true,
    context_scan_limit = 8,
    set_formatexpr = false,
}

local values = vim.deepcopy(defaults)

function M.defaults()
    return vim.deepcopy(defaults)
end

function M.get()
    return values
end

function M.setup(opts)
    values = vim.tbl_deep_extend("force", {}, defaults, opts or {})
    return values
end

function M.reset_for_tests()
    values = vim.deepcopy(defaults)
end

return M
