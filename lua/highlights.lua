if vim.g.vscode then
    return
end

local api = vim.api

local function read_hl(group)
    local ok, hl = pcall(api.nvim_get_hl, 0, { name = group, link = false })
    if not ok or type(hl) ~= "table" then
        return nil
    end
    return hl
end

local function apply_without_underlines(target_group, source_group)
    local source_hl = read_hl(source_group)
    local hl = {}
    if type(source_hl) == "table" then
        hl = vim.tbl_extend("force", hl, source_hl)
    end
    hl.underline = false
    hl.undercurl = false
    hl.underdouble = false
    hl.underdotted = false
    hl.underdashed = false
    hl.sp = nil
    api.nvim_set_hl(0, target_group, hl)
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
    api.nvim_set_hl(0, "@lsp.type.comment.c", {})
    api.nvim_set_hl(0, "@lsp.type.comment.cpp", {})
    api.nvim_set_hl(0, "@lsp.type.comment.objc", {})

    api.nvim_set_hl(0, "@lsp.mod.inactive", {})
    api.nvim_set_hl(0, "LspInactiveRegion", {})
    api.nvim_set_hl(0, "@lsp.mod.inactive.c", {})
    api.nvim_set_hl(0, "@lsp.mod.inactive.cpp", {})

    for i = 1, #lsp_inactive_types do
        local token_type = lsp_inactive_types[i]
        api.nvim_set_hl(0, "@lsp.typemod." .. token_type .. ".inactive", {})
        api.nvim_set_hl(0, "@lsp.typemod." .. token_type .. ".inactive.c", {})
        api.nvim_set_hl(0, "@lsp.typemod." .. token_type .. ".inactive.cpp", {})
    end
end

local function apply_custom_diagnostic_overrides()
    -- Used by lua/scripts/custom_diagnostics.lua
    api.nvim_set_hl(0, "CustomDiagText", { default = true, link = "DiagnosticVirtualTextError" })

    if read_hl("DiagnosticVirtualLinesError") then
        api.nvim_set_hl(0, "CustomDiagLine", { default = true, link = "DiagnosticVirtualLinesError" })
        return
    end

    local virtual_text_error = read_hl("DiagnosticVirtualTextError")
    if virtual_text_error and virtual_text_error.bg then
        api.nvim_set_hl(0, "CustomDiagLine", { default = true, bg = virtual_text_error.bg })
        return
    end

    api.nvim_set_hl(0, "CustomDiagLine", { default = true, link = "DiffDelete" })
end

local function apply_markdown_overrides()
    api.nvim_set_hl(0, "@markup.link.markdown_inline", { link = "@markup.link.label" })
    api.nvim_set_hl(0, "@markup.link.markdown", { link = "@markup.link.label" })

    apply_without_underlines("@markup.link.label.markdown_inline", "@markup.link.label")
    apply_without_underlines("@markup.list.unchecked.markdown", "@markup.list.unchecked")
    apply_without_underlines("@markup.list.checked.markdown", "@markup.list.checked")
end

local function apply_all_highlight_overrides()
    apply_lsp_semantic_overrides()
    apply_custom_diagnostic_overrides()
    apply_markdown_overrides()
end

apply_all_highlight_overrides()

local highlight_override_group = api.nvim_create_augroup("HighlightOverrides", { clear = true })
api.nvim_create_autocmd("ColorScheme", {
    group = highlight_override_group,
    callback = apply_all_highlight_overrides,
})
