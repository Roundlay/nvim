if vim.g.vscode then
    return
end

local api = vim.api
local ts = vim.treesitter

local function set_hl(group, opts)
    api.nvim_set_hl(0, group, opts)
end

local function set_hl_default(group, opts)
    set_hl(group, vim.tbl_extend("force", { default = true }, opts or {}))
end

local function get_hl(group)
    local ok, hl = pcall(api.nvim_get_hl, 0, { name = group, link = false })
    if not ok or type(hl) ~= "table" then
        return nil
    end
    return hl
end

local function copy_without_underlines(hl)
    local out = {}
    if type(hl) == "table" then
        out = vim.tbl_extend("force", out, hl)
    end
    out.underline = false
    out.undercurl = false
    out.underdouble = false
    out.underdotted = false
    out.underdashed = false
    out.sp = nil
    return out
end

local function set_hl_without_underlines(target_group, source_group)
    set_hl(target_group, copy_without_underlines(get_hl(source_group)))
end

-- clangd marks inactive #if branches as semantic-token "comment", which can
-- dim real code. Clearing inactive-token groups lets Treesitter own rendering.
local lsp_inactive_types = {
    "namespace",
    "type",
    "class",
    "enum",
    "interface",
    "struct",
    "typeParameter",
    "parameter",
    "variable",
    "property",
    "enumMember",
    "event",
    "function",
    "method",
    "macro",
    "keyword",
    "modifier",
    "comment",
    "string",
    "number",
    "regexp",
    "operator",
    "decorator",
}

local function apply_lsp_semantic_overrides()
    set_hl("@lsp.type.comment.c", {})
    set_hl("@lsp.type.comment.cpp", {})
    set_hl("@lsp.type.comment.objc", {})

    set_hl("@lsp.mod.inactive", {})
    set_hl("LspInactiveRegion", {})
    set_hl("@lsp.mod.inactive.c", {})
    set_hl("@lsp.mod.inactive.cpp", {})

    for i = 1, #lsp_inactive_types do
        local token_type = lsp_inactive_types[i]
        set_hl("@lsp.typemod." .. token_type .. ".inactive", {})
        set_hl("@lsp.typemod." .. token_type .. ".inactive.c", {})
        set_hl("@lsp.typemod." .. token_type .. ".inactive.cpp", {})
    end
end

local function apply_custom_diagnostic_overrides()
    -- Used by lua/scripts/custom_diagnostics.lua
    set_hl_default("CustomDiagText", { link = "DiagnosticVirtualTextError" })

    if get_hl("DiagnosticVirtualLinesError") then
        set_hl_default("CustomDiagLine", { link = "DiagnosticVirtualLinesError" })
        return
    end

    local virtual_text_error = get_hl("DiagnosticVirtualTextError")
    if virtual_text_error and virtual_text_error.bg then
        set_hl_default("CustomDiagLine", { bg = virtual_text_error.bg })
        return
    end

    set_hl_default("CustomDiagLine", { link = "DiffDelete" })
end

local function apply_markdown_overrides()
    set_hl("@markup.link.markdown_inline", { link = "@markup.link.label" })
    set_hl("@markup.link.markdown", { link = "@markup.link.label" })

    set_hl_without_underlines("@markup.link.label.markdown_inline", "@markup.link.label")
    set_hl_without_underlines("@markup.list.unchecked.markdown", "@markup.list.unchecked")
    set_hl_without_underlines("@markup.list.checked.markdown", "@markup.list.checked")
end

local todo_marker_ns = api.nvim_create_namespace("TodoCommentMarkers")
local comment_query_cache = {}
local marker_refresh_generation = {}
local todo_markers = {}

local function marker_group_name(marker)
    local bytes = {}
    for i = 1, #marker do
        bytes[#bytes + 1] = string.format("%02X", marker:byte(i))
    end
    return "TodoCommentMarker_" .. table.concat(bytes, "_")
end

local function register_todo_comment_marker(marker, fg, opts)
    local hl_opts = vim.tbl_extend("force", { fg = fg, bold = true }, opts or {})
    local spec = {
        marker = marker,
        marker_len = #marker,
        hl_group = marker_group_name(marker),
        hl_opts = hl_opts,
    }
    todo_markers[#todo_markers + 1] = spec
    set_hl(spec.hl_group, spec.hl_opts)
end

local function apply_todo_marker_group_overrides()
    for i = 1, #todo_markers do
        local spec = todo_markers[i]
        set_hl(spec.hl_group, spec.hl_opts)
    end
end

local function get_comment_query(lang)
    local cached = comment_query_cache[lang]
    if cached ~= nil then
        return cached or nil
    end

    local ok, query = pcall(vim.treesitter.query.parse, lang, "(comment) @comment")
    if not ok then
        comment_query_cache[lang] = false
        return nil
    end

    comment_query_cache[lang] = query
    return query
end

local function highlight_markers_on_line(buf, row, line, first_col, last_col)
    if first_col >= last_col then
        return
    end

    for i = 1, #todo_markers do
        local spec = todo_markers[i]
        local search_from = first_col + 1

        while true do
            local start_col, end_col = string.find(line, spec.marker, search_from, true)
            if not start_col then
                break
            end

            if end_col > last_col then
                break
            end

            api.nvim_buf_set_extmark(buf, todo_marker_ns, row, start_col - 1, {
                end_col = end_col,
                hl_group = spec.hl_group,
                priority = 220,
            })

            search_from = start_col + spec.marker_len
        end
    end
end

local function highlight_markers_on_comment_node(buf, node)
    local start_row, start_col, end_row, end_col = node:range()
    local lines = api.nvim_buf_get_lines(buf, start_row, end_row + 1, false)

    for i = 1, #lines do
        local row = start_row + i - 1
        local line = lines[i]
        local first_col = 0
        local last_col = #line

        if row == start_row then
            first_col = start_col
        end
        if row == end_row then
            last_col = end_col
        end

        if first_col < 0 then
            first_col = 0
        end
        if last_col > #line then
            last_col = #line
        end

        highlight_markers_on_line(buf, row, line, first_col, last_col)
    end
end

local function refresh_todo_comment_markers(buf)
    if not api.nvim_buf_is_valid(buf) then
        return
    end

    api.nvim_buf_clear_namespace(buf, todo_marker_ns, 0, -1)

    if vim.bo[buf].buftype ~= "" or #todo_markers == 0 then
        return
    end

    local ok_parser, parser = pcall(ts.get_parser, buf)
    if not ok_parser or not parser then
        return
    end

    local query = get_comment_query(parser:lang())
    if not query then
        return
    end

    local tree = parser:parse()[1]
    if not tree then
        return
    end

    local root = tree:root()
    for _, node in query:iter_captures(root, buf, 0, -1) do
        highlight_markers_on_comment_node(buf, node)
    end
end

local function schedule_todo_comment_refresh(buf)
    if not api.nvim_buf_is_valid(buf) then
        return
    end

    local generation = (marker_refresh_generation[buf] or 0) + 1
    marker_refresh_generation[buf] = generation

    vim.defer_fn(function()
        if not api.nvim_buf_is_valid(buf) then
            marker_refresh_generation[buf] = nil
            return
        end
        if marker_refresh_generation[buf] ~= generation then
            return
        end
        refresh_todo_comment_markers(buf)
    end, 18)
end

do
    local marker_palette = {
        { marker = "[ ]", fg = "#9CDCFE" },
        { marker = "[X]", fg = "#6A9955" },
        { marker = "[+]", fg = "#4EC9B0" },
        { marker = "[~]", fg = "#DCDCAA" },
        { marker = "[!]", fg = "#F44747" },
        { marker = "[@]", fg = "#C586C0" },
    }

    local palette_override = vim.g.todo_comment_marker_colours
    if type(palette_override) == "table" then
        for i = 1, #marker_palette do
            local entry = marker_palette[i]
            local override = palette_override[entry.marker]
            if type(override) == "string" and override ~= "" then
                entry.fg = override
            end
        end
    end

    for i = 1, #marker_palette do
        local entry = marker_palette[i]
        register_todo_comment_marker(entry.marker, entry.fg)
    end
end

local function apply_all_highlight_overrides()
    apply_lsp_semantic_overrides()
    apply_custom_diagnostic_overrides()
    apply_markdown_overrides()
    apply_todo_marker_group_overrides()
end

apply_all_highlight_overrides()
schedule_todo_comment_refresh(api.nvim_get_current_buf())

local highlight_override_group = api.nvim_create_augroup("HighlightOverrides", { clear = true })
api.nvim_create_autocmd("ColorScheme", {
    group = highlight_override_group,
    callback = function()
        apply_all_highlight_overrides()
        schedule_todo_comment_refresh(api.nvim_get_current_buf())
    end,
})

local todo_marker_group = api.nvim_create_augroup("TodoCommentMarkerRefresh", { clear = true })
api.nvim_create_autocmd({
    "BufEnter",
    "BufWinEnter",
    "FileType",
    "TextChanged",
    "TextChangedI",
    "InsertLeave",
    "BufWritePost",
}, {
    group = todo_marker_group,
    callback = function(args)
        schedule_todo_comment_refresh(args.buf)
    end,
})

api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = todo_marker_group,
    callback = function(args)
        marker_refresh_generation[args.buf] = nil
    end,
})
