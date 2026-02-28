if vim.g.vscode then
    return
end

if vim.g.colors_name then
    vim.cmd("highlight clear")
end

if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
end

vim.o.background = "dark"
vim.o.termguicolors = true
vim.g.colors_name = "naysayer"

local p = {
    bg = "#062329",
    bg_line = "#0B3335",
    bg_float = "#083038",
    bg_popup = "#0A2D31",
    bg_visual = "#0000FF",
    fg = "#D1B897",
    fg_alt = "#AFC6CE",
    white = "#FFFFFF",
    comments = "#15ED05",
    punctuation = "#8CDE94",
    strings = "#22B59E",
    constants = "#7AD0C6",
    numbers = "#7AD0C6",
    line = "#126367",
    error = "#FF0000",
    warning = "#FFAA00",
    info = "#66D9EF",
    hint = "#C7A538",
    diag_error = "#C74138",
    diag_hint = "#C7A538",
    violet = "#AE81FF",
    orange = "#FD971F",
    red = "#F92672",
    green = "#A6E22E",
    cyan = "#A1EFE4",
    diff_add = "#13422E",
    diff_change = "#143F4C",
    diff_delete = "#4C1F22",
    diff_text = "#205B6B",
}

vim.g.terminal_color_0 = p.bg
vim.g.terminal_color_1 = p.error
vim.g.terminal_color_2 = p.comments
vim.g.terminal_color_3 = "#E6DB74"
vim.g.terminal_color_4 = p.info
vim.g.terminal_color_5 = p.violet
vim.g.terminal_color_6 = p.strings
vim.g.terminal_color_7 = p.fg
vim.g.terminal_color_8 = p.line
vim.g.terminal_color_9 = "#FF6E64"
vim.g.terminal_color_10 = p.punctuation
vim.g.terminal_color_11 = p.warning
vim.g.terminal_color_12 = p.fg_alt
vim.g.terminal_color_13 = "#FD5FF0"
vim.g.terminal_color_14 = p.constants
vim.g.terminal_color_15 = p.white

local function hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

local function link(group, target)
    hl(group, { link = target })
end

-- Core UI
hl("Normal", { fg = p.fg, bg = p.bg })
hl("NormalNC", { fg = p.fg, bg = p.bg })
hl("NormalFloat", { fg = p.fg, bg = p.bg_float })
hl("FloatBorder", { fg = p.line, bg = p.bg_float })
hl("FloatTitle", { fg = p.white, bg = p.bg_float, bold = true })
hl("ColorColumn", { bg = p.bg_line })
hl("Conceal", { fg = p.constants, bg = p.bg })
hl("Cursor", { fg = p.bg, bg = p.white })
hl("lCursor", { fg = p.bg, bg = p.white })
hl("CursorIM", { fg = p.bg, bg = p.white })
hl("CursorColumn", { bg = p.bg_line })
hl("CursorLine", { fg = p.fg, bg = p.bg })
hl("Directory", { fg = p.fg, bg = p.bg })
hl("EndOfBuffer", { fg = p.bg, bg = p.bg })
hl("ErrorMsg", { fg = p.error, bg = p.bg, bold = true })
hl("WarningMsg", { fg = p.warning, bg = p.bg, bold = true })
hl("MoreMsg", { fg = p.green, bg = p.bg, bold = true })
hl("ModeMsg", { fg = p.white, bg = p.bg, bold = true })
hl("Question", { fg = p.green, bg = p.bg, bold = true })
hl("FoldColumn", { fg = p.line, bg = p.bg })
hl("Folded", { fg = p.comments, bg = p.bg_line })
hl("LineNr", { fg = p.fg, bg = p.bg })
hl("CursorLineNr", { fg = p.white, bg = p.bg, bold = true })
hl("LineNrPrefix", { fg = p.fg, bg = p.bg })
hl("LineNrAbove", { fg = p.fg, bg = p.bg })
hl("LineNrBelow", { fg = p.fg, bg = p.bg })
hl("SignColumn", { bg = p.bg })
hl("NonText", { fg = p.fg, bg = p.bg })
hl("SpecialKey", { fg = p.line })
hl("StatusLine", { fg = p.fg, bg = p.bg })
hl("StatusLineNC", { fg = p.bg, bg = p.fg })
hl("TabLine", { fg = p.line, bg = p.bg_line })
hl("TabLineFill", { fg = p.line, bg = p.bg })
hl("TabLineSel", { fg = p.white, bg = p.bg_line, bold = true })
hl("Title", { fg = p.white, bold = true })
hl("VertSplit", { fg = p.fg, bg = p.bg })
hl("WinSeparator", { fg = p.fg, bg = p.bg })
hl("Visual", { fg = p.bg, bg = p.fg })
hl("VisualNOS", { fg = p.bg, bg = p.fg })
hl("Whitespace", { fg = p.line })
hl("WinBar", { fg = p.fg, bg = p.bg })
hl("WinBarNC", { fg = p.line, bg = p.bg })
hl("WildMenu", { fg = p.bg, bg = p.white, bold = true })
hl("QuickFixLine", { bg = p.bg_line, bold = true })

hl("Search", { fg = p.white, bg = p.bg_visual })
hl("IncSearch", { fg = p.bg, bg = p.constants, bold = true })
hl("CurSearch", { fg = p.bg, bg = p.green, bold = true })
hl("Substitute", { fg = p.bg, bg = p.orange, bold = true })
hl("MatchParen", { fg = p.white, bg = p.bg_line, bold = true })

hl("Pmenu", { fg = p.fg, bg = p.bg })
hl("PmenuSel", { fg = p.bg, bg = p.fg })
hl("PmenuSbar", { bg = p.bg })
hl("PmenuThumb", { bg = p.fg })

hl("DiffAdd", { fg = p.comments, bg = p.diff_add })
hl("DiffChange", { fg = p.constants, bg = p.diff_change })
hl("DiffDelete", { fg = p.error, bg = p.diff_delete })
hl("DiffText", { fg = p.white, bg = p.diff_text, bold = true })

hl("SpellBad", { undercurl = true, sp = p.error })
hl("SpellCap", { undercurl = true, sp = p.info })
hl("SpellRare", { undercurl = true, sp = p.violet })
hl("SpellLocal", { undercurl = true, sp = p.warning })

hl("CustomDiagText", { fg = "#FF8892", bg = "#3C1317" })
hl("CustomDiagLine", { bg = "#2D1013" })

-- Diagnostics
hl("DiagnosticError", { fg = p.diag_error, bg = p.bg })
hl("DiagnosticWarn", { fg = p.warning })
hl("DiagnosticInfo", { fg = p.info })
hl("DiagnosticHint", { fg = p.diag_hint, bg = p.bg })
hl("DiagnosticOk", { fg = p.green })

hl("DiagnosticSignError", { fg = p.diag_error, bg = p.bg })
hl("DiagnosticSignWarn", { fg = p.warning, bg = p.bg })
hl("DiagnosticSignInfo", { fg = p.info, bg = p.bg })
hl("DiagnosticSignHint", { fg = p.diag_hint, bg = p.bg })
hl("DiagnosticSignOk", { fg = p.green, bg = p.bg })

hl("DiagnosticVirtualTextError", { fg = "#FF6E64", bg = "#2D1013" })
hl("DiagnosticVirtualTextWarn", { fg = "#FFD27A", bg = "#2D2310" })
hl("DiagnosticVirtualTextInfo", { fg = "#95E8FF", bg = "#0F2A31" })
hl("DiagnosticVirtualTextHint", { fg = "#B5F3B3", bg = "#102A1A" })
hl("DiagnosticVirtualTextOk", { fg = "#C9FF7A", bg = "#162D13" })

hl("DiagnosticFloatingError", { fg = p.error, bg = p.bg_float })
hl("DiagnosticFloatingWarn", { fg = p.warning, bg = p.bg_float })
hl("DiagnosticFloatingInfo", { fg = p.info, bg = p.bg_float })
hl("DiagnosticFloatingHint", { fg = p.hint, bg = p.bg_float })
hl("DiagnosticFloatingOk", { fg = p.green, bg = p.bg_float })

hl("DiagnosticUnderlineError", { undercurl = true, sp = p.error })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = p.warning })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = p.info })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = p.hint })
hl("DiagnosticUnderlineOk", { undercurl = true, sp = p.green })

hl("LspReferenceText", { bg = p.bg_line })
hl("LspReferenceRead", { bg = p.bg_line })
hl("LspReferenceWrite", { bg = p.bg_line, bold = true })
hl("LspInlayHint", { fg = p.line, bg = p.bg_line, italic = true })
hl("LspCodeLens", { fg = p.line, italic = true })
hl("LspCodeLensSeparator", { fg = p.line })

-- Syntax
hl("Comment", { fg = p.comments })
hl("Constant", { fg = p.constants })
hl("String", { fg = p.strings })
hl("Character", { fg = p.strings })
hl("Number", { fg = p.numbers })
hl("Boolean", { fg = p.constants, bold = true })
hl("Float", { fg = p.numbers })
hl("Identifier", { fg = p.fg_alt })
hl("Function", { fg = p.fg })
hl("Statement", { fg = p.fg })
hl("Conditional", { fg = p.white })
hl("Repeat", { fg = p.white })
hl("Label", { fg = p.white })
hl("Operator", { fg = p.punctuation })
hl("Keyword", { fg = p.white })
hl("Exception", { fg = p.error })
hl("PreProc", { fg = p.punctuation })
hl("Include", { fg = p.punctuation })
hl("Define", { fg = p.punctuation })
hl("Macro", { fg = p.punctuation })
hl("PreCondit", { fg = p.punctuation })
hl("Type", { fg = p.punctuation })
hl("StorageClass", { fg = p.punctuation })
hl("Structure", { fg = p.punctuation })
hl("Typedef", { fg = p.punctuation })
hl("Special", { fg = p.punctuation })
hl("SpecialChar", { fg = p.constants })
hl("Tag", { fg = p.punctuation })
hl("Delimiter", { fg = p.punctuation })
hl("SpecialComment", { fg = p.comments })
hl("Debug", { fg = p.warning })
hl("Underlined", { fg = p.constants, underline = true })
hl("Ignore", { fg = p.punctuation })
hl("Error", { fg = p.error, bold = true })
hl("Todo", { fg = p.warning })

-- Treesitter
link("@comment", "Comment")
link("@comment.documentation", "Comment")
link("@comment.todo", "Todo")
link("@punctuation", "Delimiter")
link("@punctuation.delimiter", "Delimiter")
link("@punctuation.bracket", "Delimiter")
link("@punctuation.special", "Special")
link("@constant", "Constant")
link("@constant.builtin", "Constant")
link("@constant.macro", "Macro")
link("@string", "String")
link("@string.documentation", "String")
hl("@string.regexp", { fg = p.orange })
link("@string.escape", "SpecialChar")
link("@string.special", "SpecialChar")
link("@character", "Character")
link("@character.special", "SpecialChar")
link("@number", "Number")
link("@number.float", "Float")
link("@boolean", "Boolean")
link("@float", "Float")
link("@function", "Function")
hl("@function.builtin", { fg = p.white, bold = true })
hl("@function.call", { fg = p.white })
hl("@function.macro", { fg = p.punctuation })
link("@method", "Function")
link("@method.call", "Function")
hl("@constructor", { fg = p.white })
hl("@parameter", { fg = p.fg_alt })
hl("@parameter.reference", { fg = p.fg_alt })
hl("@property", { fg = p.fg })
hl("@field", { fg = p.fg })
hl("@variable", { fg = p.fg_alt })
hl("@variable.builtin", { fg = p.constants, bold = true })
hl("@variable.member", { fg = p.fg })
hl("@variable.parameter", { fg = p.fg_alt })
hl("@module", { fg = p.fg_alt })
hl("@namespace", { fg = p.fg_alt })
link("@type", "Type")
hl("@type.builtin", { fg = p.white })
hl("@type.definition", { fg = p.punctuation })
link("@attribute", "PreProc")
link("@keyword", "Keyword")
hl("@keyword.function", { fg = p.white, bold = true })
hl("@keyword.operator", { fg = p.punctuation })
hl("@keyword.return", { fg = p.white, bold = true })
hl("@keyword.import", { fg = p.punctuation })
hl("@keyword.exception", { fg = p.white, bold = true })
link("@operator", "Operator")
hl("@label", { fg = p.white, bold = true })
hl("@tag", { fg = p.punctuation })
hl("@tag.attribute", { fg = p.constants })
hl("@tag.delimiter", { fg = p.punctuation })
hl("@markup.strong", { bold = true })
hl("@markup.italic", { italic = true })
hl("@markup.strikethrough", { strikethrough = true })
hl("@markup.underline", { underline = true })
hl("@markup.heading", { fg = p.white, bold = true })
hl("@markup.heading.1", { fg = p.white, bold = true })
hl("@markup.heading.2", { fg = p.white, bold = true })
hl("@markup.heading.3", { fg = p.fg, bold = true })
hl("@markup.list", { fg = p.punctuation })
hl("@markup.list.checked", { fg = p.green })
hl("@markup.list.unchecked", { fg = p.warning })
hl("@markup.quote", { fg = p.comments, italic = true })
hl("@markup.math", { fg = p.constants })
hl("@markup.link", { fg = p.constants, underline = true })
hl("@markup.link.url", { fg = p.info, underline = true })
hl("@markup.raw", { fg = p.strings })
hl("@diff.plus", { fg = p.comments })
hl("@diff.minus", { fg = p.error })
hl("@diff.delta", { fg = p.constants })

-- LSP semantic tokens
link("@lsp.type.comment", "@comment")
link("@lsp.type.keyword", "@keyword")
link("@lsp.type.operator", "@operator")
link("@lsp.type.string", "@string")
link("@lsp.type.number", "@number")
link("@lsp.type.boolean", "@boolean")
link("@lsp.type.function", "@function")
link("@lsp.type.method", "@method")
link("@lsp.type.variable", "@variable")
link("@lsp.type.parameter", "@parameter")
link("@lsp.type.property", "@property")
link("@lsp.type.type", "@type")
link("@lsp.type.class", "@type")
link("@lsp.type.enum", "@type")
link("@lsp.type.enumMember", "@constant")
link("@lsp.type.namespace", "@namespace")
hl("@lsp.mod.deprecated", { strikethrough = true })
link("@lsp.mod.readonly", "@constant")

-- Common plugin groups
hl("GitSignsAdd", { fg = p.comments, bg = p.bg })
hl("GitSignsChange", { fg = p.constants, bg = p.bg })
hl("GitSignsDelete", { fg = p.error, bg = p.bg })
hl("SignAdd", { fg = p.comments, bg = p.bg })
hl("SignChange", { fg = p.constants, bg = p.bg })
hl("SignDelete", { fg = p.error, bg = p.bg })

hl("TelescopeNormal", { fg = p.fg, bg = p.bg_float })
hl("TelescopeBorder", { fg = p.line, bg = p.bg_float })
hl("TelescopePromptNormal", { fg = p.fg, bg = p.bg_popup })
hl("TelescopePromptBorder", { fg = p.line, bg = p.bg_popup })
hl("TelescopePromptTitle", { fg = p.bg, bg = p.constants, bold = true })
hl("TelescopePreviewTitle", { fg = p.bg, bg = p.comments, bold = true })
hl("TelescopeResultsTitle", { fg = p.bg, bg = p.white, bold = true })
hl("TelescopeSelection", { fg = p.white, bg = p.bg_line, bold = true })
hl("TelescopeMatching", { fg = p.constants, bold = true })

hl("CmpItemAbbr", { fg = p.fg })
hl("CmpItemAbbrMatch", { fg = p.constants, bold = true })
hl("CmpItemAbbrMatchFuzzy", { fg = p.constants, bold = true })
hl("CmpItemAbbrDeprecated", { fg = p.line, strikethrough = true })
hl("CmpItemMenu", { fg = p.line })
hl("CmpItemKind", { fg = p.fg_alt })
hl("CmpItemKindFunction", { fg = p.white })
hl("CmpItemKindMethod", { fg = p.white })
hl("CmpItemKindVariable", { fg = p.fg_alt })
hl("CmpItemKindKeyword", { fg = p.white })
hl("CmpItemKindClass", { fg = p.punctuation })
hl("CmpItemKindInterface", { fg = p.punctuation })
hl("CmpItemKindModule", { fg = p.fg_alt })
hl("CmpItemKindSnippet", { fg = p.orange })
hl("CmpItemKindFile", { fg = p.constants })
hl("CmpItemKindFolder", { fg = p.constants })

hl("BlinkCmpMenu", { fg = p.fg, bg = p.bg_popup })
hl("BlinkCmpMenuBorder", { fg = p.line, bg = p.bg_popup })
hl("BlinkCmpLabel", { fg = p.fg })
hl("BlinkCmpLabelMatch", { fg = p.constants, bold = true })
hl("BlinkCmpLabelDeprecated", { fg = p.line, strikethrough = true })
hl("BlinkCmpKind", { fg = p.fg_alt })
hl("BlinkCmpKindFunction", { fg = p.white })
hl("BlinkCmpKindMethod", { fg = p.white })
hl("BlinkCmpKindVariable", { fg = p.fg_alt })
hl("BlinkCmpKindKeyword", { fg = p.white })
hl("BlinkCmpDoc", { fg = p.fg, bg = p.bg_float })
hl("BlinkCmpDocBorder", { fg = p.line, bg = p.bg_float })
hl("BlinkCmpSignatureHelp", { fg = p.fg, bg = p.bg_float })
hl("BlinkCmpSignatureHelpBorder", { fg = p.line, bg = p.bg_float })

hl("IblIndent", { fg = p.line })
hl("IblScope", { fg = p.constants })

hl("FlashLabel", { fg = p.bg, bg = p.warning, bold = true })
hl("FlashMatch", { fg = p.bg, bg = p.constants })
hl("FlashCurrent", { fg = p.bg, bg = p.green, bold = true })
hl("FlashBackdrop", { fg = p.line })
hl("FlashPrompt", { fg = p.white, bg = p.bg_line })

hl("OilDir", { fg = p.constants, bold = true })
hl("OilDirIcon", { fg = p.constants })
hl("OilSocket", { fg = p.warning })
hl("OilLink", { fg = p.info, underline = true })

hl("LazyNormal", { fg = p.fg, bg = p.bg })
hl("LazyButton", { fg = p.fg, bg = p.bg })
hl("LazyButtonActive", { fg = p.bg, bg = p.fg, bold = true })
hl("LazySpecial", { fg = p.constants })
hl("LazyH1", { fg = p.bg, bg = p.white, bold = true })

hl("MasonNormal", { fg = p.fg, bg = p.bg })
hl("MasonHeader", { fg = p.bg, bg = p.white, bold = true })
hl("MasonHeaderSecondary", { fg = p.bg, bg = p.constants, bold = true })
hl("MasonHighlight", { fg = p.constants })
hl("MasonHighlightBlock", { fg = p.bg, bg = p.constants, bold = true })
