-- highlights.lua

if vim.g.vscode then
    return
end

-- NOTE: It's so stupid that I have to do this.
-- NONE = NONE

-- vim.api.nvim_set_hl(0, "LineNr", {fg = sumiInk2, bg = NONE, gui = NONE}) -- Kanagawa
-- vim.api.nvim_set_hl(0, "LineNr", { fg = "#7d7d7d", ctermfg = 244 })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffffff", ctermfg = 15, bold = true })
vim.api.nvim_set_hl(0, "LineNrPrefix", { fg = "#2d2d2d", ctermfg = 238 })

-- vim.api.nvim_set_hl(0, 'LeapBackdrop', { fg = sumiInk4, bg = NONE, gui = NONE }) -- Kanagawa
vim.api.nvim_set_hl(0, 'Cursor', { reverse = true })

-- vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = winterBlue}) -- Kanagawa
-- vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = "#4d4d4d"})
-- vim.api.nvim_set_hl(0, "@curlybraces", {fg = sumiInk3})
vim.api.nvim_set_hl(0, 'SearchCounterDim', { fg = '#363646' })

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "txt", "todo" },
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
            { name = "TodoAlert", opts = { fg = "#df4540" , bold = true } },
            { name = "TodoMiddle", opts = { fg = "#df6540" , bold = true } },
            { name = "TodoAmbiguous", opts = { fg = "#6540df" , bold = true } },
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

vim.cmd [[ highlight NonText cterm=NONE ctermfg=NONE ]] -- See term.txt in the docs
vim.cmd [[ highlight WinSeparator guifg=bg guibg=bg cterm=NONE ]]

vim.api.nvim_set_hl(0, 'FlashLabel', { fg = 0xf00823 })
vim.api.nvim_set_hl(0, 'FlashCursor', { fg = 0xffffff })
-- vim.api.nvim_set_hl(0, 'FlashBackdrop', { fg = 0x360714 })
