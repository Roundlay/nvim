if vim.g.vscode then
    return
end

-- Helper function to set highlights more easily
local function set_hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

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

-- Window divider highlights for narrow unfocused windows
set_hl("VertSplit", { fg = "#68217A", bg = "NONE", bold = true })  -- Purple divider
set_hl("WinSeparator", { fg = "#68217A", bg = "NONE", bold = true })  -- For newer Neovim versions

-- Cursor and search highlights
set_hl("Cursor", { reverse = true })
set_hl("SearchCounterDim", { fg = "#363646" })

-- Indentation and braces
set_hl("IndentBlanklineChar", { fg = "#3d3d3d" })
set_hl("@curlybraces", { fg = "#3d3d3d" })

-- Flash plugin highlights
-- set_hl("FlashLabel", { fg = 0xf00823 })
-- set_hl("FlashCursor", { fg = 0xffffff })

vim.api.nvim_set_hl(0, "cBlock", { fg = vim.fn.synIDattr(vim.fn.hlID("Normal"), "fg"), bg = "NONE" })

-- Todo functionality for markdown files
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "*", },
    callback = function()
        -- Define patterns and their associated highlight groups
        local patterns = {
            { pattern = "\\[\\]", hl_group = "TodoPattern" },
            { pattern = "\\[ \\]", hl_group = "TodoPattern" },
            { pattern = "\\[-\\]", hl_group = "TodoPattern" },
            { pattern = "\\[+\\]", hl_group = "TodoPattern" },
            { pattern = "\\[X\\]", hl_group = "TodoComplete" },
            { pattern = "\\[x\\]", hl_group = "TodoComplete" },
            { pattern = "\\[?\\]", hl_group = "TodoAmbiguous" },
            { pattern = "\\[>\\]", hl_group = "TodoAmbiguous" },
            { pattern = "\\[<\\]", hl_group = "TodoAmbiguous" },
            { pattern = "\\[!\\]", hl_group = "TodoAlert" },
            { pattern = "\\[/\\]", hl_group = "TodoAlert" }
        }
        -- Loop over patterns and apply the highlights
        for _, p in ipairs(patterns) do
            vim.fn.matchadd(p.hl_group, p.pattern)
        end
        -- Set the highlights for the groups
        local highlight_groups = {
            -- Emerald green pantone: #00b140
            { name = "TodoPattern", opts = { fg = "#7fb4ca", bold = true } },
            { name = "TodoComplete", opts = { fg = "#40df65", bold = true } },
            { name = "TodoAlert", opts = { fg = "#df4540", bold = true } },
            { name = "TodoMiddle", opts = { fg = "#df6540", bold = true } },
            { name = "TodoAmbiguous", opts = { fg = "#6540df", bold = true } },
            { name = "@markup.link", opts = { fg = "#7fb4ca", bold = true, underline = false } },
            { name = "@markup.list.checked.markdown", opts = { fg = "#7fb4ca", bold = true, underline = false } },
            { name = "@markup.list.unchecked.markdown", opts = { fg = "#7fb4ca", bold = true, underline = false } }
        }
        -- Loop over the highlight groups and set their properties
        for _, hl in ipairs(highlight_groups) do
            vim.api.nvim_set_hl(0, hl.name, hl.opts)
        end
    end,
})

-- local p = {                   -- single source of truth
--   front     = '#343434',
--   back      = '#FFFFFF',
--   popupF    = '#000000',
--   popupB    = '#F8F8F8',
--   popBlue   = '#0064c1',
--   gutter    = '#E5E5E5',
--   thumb     = '#DFDFDF',
--   border    = '#DDDDDD',
--   selectBG  = '#ADD6FF',
--   suggest   = '#868686',
--   redLight  = '#FFA3A3',
--   yellow    = '#795E26',
--   green     = '#008000',
--   blueG     = '#16825D',
--   dBlue     = '#007ACC',
--   violet    = '#000080',
--   orange    = '#C72E0F',
--   lRed      = '#A31515',
--   red       = '#FF0000',
--   pink      = '#AF00DB',
-- }
--
-- set_hl("BlinkCmpMenu",                         { fg = p.popupF,   bg = p.popupB })
-- set_hl("BlinkCmpMenuBorder",                   { fg = p.border,   bg = p.popupB })
-- set_hl("BlinkCmpMenuSelection",                { fg = p.popupF,   bg = p.selectBG, bold = true })
-- set_hl("BlinkCmpScrollBarGutter",              { bg = p.gutter })
-- set_hl("BlinkCmpScrollBarThumb",               { bg = p.thumb  })
-- set_hl("BlinkCmpLabel",                        { fg = p.popupF })
-- set_hl("BlinkCmpLabelDeprecated",              { fg = p.suggest,  strikethrough = true })
-- set_hl("BlinkCmpLabelMatch",                   { fg = p.popBlue,  bold = true })
-- set_hl("BlinkCmpLabelDetail",                  { fg = p.suggest })
-- set_hl("BlinkCmpLabelDescription",             { fg = p.suggest })
-- set_hl("BlinkCmpKind",                         { fg = p.suggest })
-- set_hl("BlinkCmpKindText",                     { fg = p.suggest })
-- set_hl("BlinkCmpKindMethod",                   { fg = p.yellow })
-- set_hl("BlinkCmpKindFunction",                 { fg = p.yellow })
-- set_hl("BlinkCmpKindConstructor",              { fg = p.green })
-- set_hl("BlinkCmpKindField",                    { fg = p.blueG })
-- set_hl("BlinkCmpKindVariable",                 { fg = p.dBlue })
-- set_hl("BlinkCmpKindClass",                    { fg = p.violet })
-- set_hl("BlinkCmpKindInterface",                { fg = p.violet })
-- set_hl("BlinkCmpKindModule",                   { fg = p.pink })
-- set_hl("BlinkCmpKindProperty",                 { fg = p.blueG })
-- set_hl("BlinkCmpKindUnit",                     { fg = p.dBlue })
-- set_hl("BlinkCmpKindValue",                    { fg = p.dBlue })
-- set_hl("BlinkCmpKindEnum",                     { fg = p.orange })
-- set_hl("BlinkCmpKindKeyword",                  { fg = p.pink })
-- set_hl("BlinkCmpKindSnippet",                  { fg = p.lRed })
-- set_hl("BlinkCmpKindColor",                    { fg = p.red })
-- set_hl("BlinkCmpKindFile",                     { fg = p.orange })
-- set_hl("BlinkCmpKindReference",                { fg = p.red })
-- set_hl("BlinkCmpKindFolder",                   { fg = p.orange })
-- set_hl("BlinkCmpKindEnumMember",               { fg = p.orange })
-- set_hl("BlinkCmpKindConstant",                 { fg = p.dBlue })
-- set_hl("BlinkCmpKindStruct",                   { fg = p.violet })
-- set_hl("BlinkCmpKindEvent",                    { fg = p.yellow })
-- set_hl("BlinkCmpKindOperator",                 { fg = p.front })
-- set_hl("BlinkCmpKindTypeParameter",            { fg = p.violet })
-- set_hl("BlinkCmpSource",                       { fg = p.suggest })
-- set_hl("BlinkCmpGhostText",                    { fg = p.suggest, italic = true })
-- set_hl("BlinkCmpDoc",                          { fg = p.front, bg = p.back })
-- set_hl("BlinkCmpDocBorder",                    { fg = p.border, bg = p.back })
-- set_hl("BlinkCmpDocSeparator",                 { fg = p.border })
-- set_hl("BlinkCmpDocCursorLine",                { bg = p.selectBG })
-- set_hl("BlinkCmpSignatureHelp",                { fg = p.front, bg = p.back })
-- set_hl("BlinkCmpSignatureHelpBorder",          { fg = p.border, bg = p.back })
-- set_hl("BlinkCmpSignatureHelpActiveParameter", { bg = p.redLight, underline = true })

vim.api.nvim_set_hl(0, "@lsp.type.unnecessary", { link = "Normal" })

vim.api.nvim_set_hl(0, "CReturnType", { fg = "#808080" })
