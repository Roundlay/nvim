if vim.g.vscode then
    return
end

local api = vim.api

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

local markdown_no_underline_groups = {
    { "@markup.link.label.markdown_inline", "@markup.link.label" },
    { "@markup.list.unchecked.markdown", "@markup.list.unchecked" },
    { "@markup.list.checked.markdown", "@markup.list.checked" },
}

-- clangd marks inactive #if branches as semantic-token "comment", which can
-- dim real code. Clearing inactive-token groups lets Treesitter own rendering.
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

-- Used by lua/scripts/custom_diagnostics.lua
api.nvim_set_hl(0, "CustomDiagText", { default = true, link = "DiagnosticVirtualTextError" })
do
    local ok_lines, virtual_lines_error = pcall(api.nvim_get_hl, 0, { name = "DiagnosticVirtualLinesError", link = false })
    if ok_lines and type(virtual_lines_error) == "table" then
        api.nvim_set_hl(0, "CustomDiagLine", { default = true, link = "DiagnosticVirtualLinesError" })
    else
        local ok_text, virtual_text_error = pcall(api.nvim_get_hl, 0, { name = "DiagnosticVirtualTextError", link = false })
        if ok_text and type(virtual_text_error) == "table" and virtual_text_error.bg then
            api.nvim_set_hl(0, "CustomDiagLine", { default = true, bg = virtual_text_error.bg })
        else
            api.nvim_set_hl(0, "CustomDiagLine", { default = true, link = "DiffDelete" })
        end
    end
end

api.nvim_set_hl(0, "@markup.link.markdown_inline", { link = "@markup.link.label" })
api.nvim_set_hl(0, "@markup.link.markdown", { link = "@markup.link.label" })

for i = 1, #markdown_no_underline_groups do
    local target_group = markdown_no_underline_groups[i][1]
    local source_group = markdown_no_underline_groups[i][2]
    local ok_source, source_hl = pcall(api.nvim_get_hl, 0, { name = source_group, link = false })
    local hl = {}
    if ok_source and type(source_hl) == "table" then
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

local highlight_override_group = api.nvim_create_augroup("HighlightOverrides", { clear = true })
api.nvim_create_autocmd("ColorScheme", {
    group = highlight_override_group,
    callback = function()
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

        api.nvim_set_hl(0, "CustomDiagText", { default = true, link = "DiagnosticVirtualTextError" })
        do
            local ok_lines, virtual_lines_error = pcall(api.nvim_get_hl, 0, { name = "DiagnosticVirtualLinesError", link = false })
            if ok_lines and type(virtual_lines_error) == "table" then
                api.nvim_set_hl(0, "CustomDiagLine", { default = true, link = "DiagnosticVirtualLinesError" })
            else
                local ok_text, virtual_text_error = pcall(api.nvim_get_hl, 0, { name = "DiagnosticVirtualTextError", link = false })
                if ok_text and type(virtual_text_error) == "table" and virtual_text_error.bg then
                    api.nvim_set_hl(0, "CustomDiagLine", { default = true, bg = virtual_text_error.bg })
                else
                    api.nvim_set_hl(0, "CustomDiagLine", { default = true, link = "DiffDelete" })
                end
            end
        end

        api.nvim_set_hl(0, "@markup.link.markdown_inline", { link = "@markup.link.label" })
        api.nvim_set_hl(0, "@markup.link.markdown", { link = "@markup.link.label" })

        for i = 1, #markdown_no_underline_groups do
            local target_group = markdown_no_underline_groups[i][1]
            local source_group = markdown_no_underline_groups[i][2]
            local ok_source, source_hl = pcall(api.nvim_get_hl, 0, { name = source_group, link = false })
            local hl = {}
            if ok_source and type(source_hl) == "table" then
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
    end,
})
