-- highlights.lua

if vim.g.vscode then
    return
end

local sumiInk2 = "#2A2A37"
local winterBlue = "#252535"
local sumiInk3 = "#363646"
local sumiInk4 = "#54546D"

-- NOTE: It's so stupid that I have to do this.
NONE = NONE

vim.api.nvim_set_hl(0, 'LeapBackdrop', { fg = sumiInk4, bg = NONE, gui = NONE })
-- vim.api.nvim_set_hl(0, "LineNr", {fg = sumiInk2, bg = NONE, gui = NONE})
vim.api.nvim_set_hl(0, "IndentBlanklineChar", {fg = winterBlue})
vim.api.nvim_set_hl(0, "@curlybraces", {fg = sumiInk3})
vim.api.nvim_set_hl(0, 'SearchCounterDim', { fg = '#363646' })

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "txt", "todo" },
    callback = function()
        -- Highlight `- [ ]`, `- []`, and `- [X]` patterns
        vim.fn.matchadd("TodoPattern", "- \\[ \\]")
        vim.fn.matchadd("TodoPattern", "- \\[X\\]")
        vim.fn.matchadd("TodoPattern", "- \\[\\]")
        
        -- Apply bold highlighting to the matched patterns
        vim.api.nvim_set_hl(0, "TodoPattern", { fg = "#7fb4ca", bold = true })
        vim.api.nvim_set_hl(0, "@markup.link", { fg = "#7fb4ca", bold = true, underline = false })
        vim.api.nvim_set_hl(0, "@markup.list.checked.markdown", { fg = "#7fb4ca", bold = true, underline = false })
        vim.api.nvim_set_hl(0, "@markup.list.unchecked.markdown", { fg = "#7fb4ca", bold = true, underline = false })
    end,
})
vim.cmd [[ highlight NonText cterm=NONE ctermfg=NONE ]] -- See term.txt in the docs
vim.cmd [[ highlight WinSeparator guifg=bg guibg=bg cterm=NONE ]]