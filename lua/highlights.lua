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

vim.api.nvim_set_hl(0, "@lsp.type.unnecessary", { link = "Normal" })
vim.api.nvim_set_hl(0, "CReturnType", { fg = "#808080" })
