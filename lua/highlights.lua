if vim.g.vscode then
    return
end

-- Helper function to set highlights more easily
local function set_hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

-- LSP semantic overrides (avoid dimming inactive #if regions).
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
    -- clangd marks inactive #if regions as semantic token type "comment".
    -- Clear LSP comment highlighting for C/C++ so treesitter handles it instead.
    -- This prevents inactive preprocessor blocks from being grayed out.
    set_hl("@lsp.type.comment.c", {})
    set_hl("@lsp.type.comment.cpp", {})
    set_hl("@lsp.type.comment.objc", {})

    -- Also clear inactive region highlights (for other LSP servers)
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
apply_lsp_semantic_overrides()
local lsp_semantic_group = vim.api.nvim_create_augroup("LspSemanticOverrides", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
    group = lsp_semantic_group,
    callback = apply_lsp_semantic_overrides,
})

-- Visual Studio Dark inspired tab colors
set_hl("TabLine", { fg = "#969696", bg = "#252526" }) -- Inactive tabs
set_hl("TabLineFill", { bg = "#1E1E1E" }) -- Tab line background
set_hl("TabLineSel", { fg = "#FFFFFF", bg = "#68217A", bold = true }) -- Active tab (iconic VS purple)

-- Line number highlights
set_hl("LineNr", { fg = "#7d7d7d", ctermfg = 244 })
set_hl("CursorLineNr", { fg = "#ffffff", ctermfg = 15, bold = true })
set_hl("LineNrPrefix", { fg = "#404040", ctermfg = 238 })

-- Custom Virtual Diagnostic Highlights
set_hl("CustomDiagText", { fg = "#f00823", bg = "#360714" })
set_hl("CustomDiagLine", { bg = "#5a1f1f" })

-- XML-style tags in markdown (e.g., <example>, </example>)
set_hl("MarkdownXmlTag", { fg = "#d7ba7d", bold = true })
set_hl("MarkdownInlineCode", { link = "@markup.raw.markdown_inline" })
set_hl("MarkdownBracketPlain", { link = "Normal" })

-- Markdown nested list markers - cycling colors by depth
-- These are applied dynamically by scripts/markdown_list_hl.lua
set_hl("MarkdownList1", { fg = "#7fb4ca", bold = true }) -- blue (level 0, 6, ...)
set_hl("MarkdownList2", { fg = "#98c379", bold = true }) -- green (level 1, 7, ...)
set_hl("MarkdownList3", { fg = "#d7ba7d", bold = true }) -- yellow (level 2, 8, ...)
set_hl("MarkdownList4", { fg = "#c678dd", bold = true }) -- purple (level 3, 9, ...)
set_hl("MarkdownList5", { fg = "#e06c75", bold = true }) -- red (level 4, 10, ...)
set_hl("MarkdownList6", { fg = "#d19a66", bold = true }) -- orange (level 5, 11, ...)

local function strip_underline(hl)
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

local function apply_markdown_overrides()
    set_hl("@markup.link.markdown_inline", { link = "@markup.link.label" })
    set_hl("@markup.link.markdown", { link = "@markup.link.label" })

    local ok_link, link_hl = pcall(vim.api.nvim_get_hl, 0, { name = "@markup.link.label", link = false })
    set_hl("@markup.link.label.markdown_inline", strip_underline(ok_link and link_hl or nil))

    local ok_unchecked, unchecked_hl =
        pcall(vim.api.nvim_get_hl, 0, { name = "@markup.list.unchecked", link = false })
    set_hl("@markup.list.unchecked.markdown", strip_underline(ok_unchecked and unchecked_hl or nil))

    local ok_checked, checked_hl = pcall(vim.api.nvim_get_hl, 0, { name = "@markup.list.checked", link = false })
    set_hl("@markup.list.checked.markdown", strip_underline(ok_checked and checked_hl or nil))
end

apply_markdown_overrides()
local markdown_override_group = vim.api.nvim_create_augroup("MarkdownHighlightOverrides", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
    group = markdown_override_group,
    callback = apply_markdown_overrides,
})

-- Window divider highlights for narrow unfocused windows
set_hl("VertSplit", { fg = "#404040", bg = "NONE", bold = true })
-- set_hl("WinSeparator", { fg = "#68217A", bg = "NONE", bold = true })

-- Indentation and braces
-- set_hl("IndentBlanklineChar", { fg = "#3d3d3d" })
