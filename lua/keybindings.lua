local scripts = require("scripts")

-- keybindings.lua
-- -------------------------------------------------------------------------- --

-- Helper Functions
-- -------------------------------------------------------------------------- --

function map(mode, new, old, opts)
    -- map("n", ";f", ":Telescope find_files<CR>", {expr = true})
    local default_opts = {}
    if opts then
        -- Merges the `default_opts` and `opts` tables
        options = vim.tbl_extend("force", default_opts, opts)
    end
    vim.api.nvim_set_keymap(mode, new, old, options)
end

function insert(new, old)
    vim.api.nvim_set_keymap('i', new, old, {noremap=true, silent=true})
end

function normal(new, old)
    vim.api.nvim_set_keymap('n', new, old, {noremap=true, silent=true})
end

function visual(new, old)
    vim.api.nvim_set_keymap('v', new, old, {noremap=true, silent=true})
end

function terminal(new, old)
    vim.api.nvim_set_keymap('t', new, old, {buffer = 0})
end

if (vim.g.vscode) then
    
    normal('J', '}') -- Jump n paragraphs backwards.
    normal('K', '{') -- Jump n paragraphs forwards.
    normal('L', '$') -- Jump to the end of the active line.
    normal('H', '_') -- Jump to the beginning of the active line.
    visual('J', '}') -- Jump n paragraphs backwards in visual mode.
    visual('K', '{') -- Jump n paragraphs forwards in visual mode.
    -- normal('<n>', '<C-v>') -- WIN: Fixes paste overlap w/ Visual Command Mode.

else

    normal('<n>', '<C-v>') -- WIN: Fixes paste overlap w/ Visual Command Mode.

    vim.g.mapleader = ' ' -- `vim.g.mapleader = '<Space>'` doesn't work.

    -- Escape
    -- ---------------------------------------------------------------------- --

    -- normal('<C-j>', '<esc>')
    -- visual('<C-j>', '<esc>')
    -- insert('<C-j>', '<esc>')
    -- normal('<leader-o>', 'o<Esc>^D0')

    -- Navigation
    -- ---------------------------------------------------------------------- --

    -- Jump forwards and back by paragraphs in Normal mode.

    normal('J', '}')
    normal('K', '{')

    -- Jump to the beginning and end of the active line in Visual mode.

    visual('J', '}')
    visual('K', '{')

    -- Jump to the beginning and end of the active line in Normal mode.

    normal('L', '$')
    normal('H', '_')

    -- Yank & Put
    -- ---------------------------------------------------------------------- --

    -- Put & Re-yank Original Selection

    visual('p', 'pgvy')

    -- Yank to System Clipboard

    normal('<leader>y', '"+y')
    normal('<leader>yy', '"+yy')
    normal('<leader>Y', '"+Y')
    visual('<leader>y', '"+y')

    -- Put from System Clipboard

    normal('<leader>p', '"+p')
    normal('<leader>P', '"+P')
    visual('<leader>p', '"+p')
    visual('<leader>P', '"+P')

    -- ---------------------------------------------------------------------- --
    -- Custom
    -- ---------------------------------------------------------------------- --

    -- Odin
    -- ---------------------------------------------------------------------- --

    -- normal('<leader>O', ':lua RunOrf()<CR>')

    -- Ebert
    -- ---------------------------------------------------------------------- --

    vim.api.nvim_set_keymap('n', '<leader>eb', ':lua require("scripts").Ebert()<CR>', {noremap = true, silent = false})

    -- ---------------------------------------------------------------------- --
    -- Plugins 
    -- ---------------------------------------------------------------------- --

    -- CoC
    -- ---------------------------------------------------------------------- --

    -- function _G.check_back_space()
    --     local col = vim.fn.col('.') - 1
    --     return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
    -- end

    -- local coc_opts = {
    --     silent=true,
    --     noremap=true,
    --     expr=true, 
    --     replace_keycodes=false
    -- }

    -- map('i', '<C-l>', [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR><Esc>"]], coc_opts) -- This seems irrelevant... I can just space out of the selection...
    -- normal('gd', '<Plug>(coc-definition)') -- CoC: Go to definition
    -- normal('[g', '<Plug>(coc-diagnostic-prev)') -- CoC: Go to previous diagnostic
    -- normal(']g', '<Plug>(coc-diagnostic-next)') -- CoC: Go to next diagnostic

    -- Your language server must support hover for this to work.

    -- function _G.show_docs()
    --     local cw = vim.fn.expand('<cword>')
    --     if vim.fn.index({'vim', 'help'}, vim.bo.filetype) >= 0 then
    --         vim.api.nvim_command('h ' .. cw)
    --     elseif vim.api.nvim_eval('coc#rpc#ready()') then
    --         vim.fn.CocActionAsync('doHover')
    --     else
    --         vim.api.nvim_command('!' .. vim.o.keywordprg .. ' ' .. cw)
    --     end
    -- end
    -- normal('<leader>d', '<cmd>lua show_docs()<CR>')

    -- Leap
    -- ---------------------------------------------------------------------- --

    -- Deleting x so Leap's overriding of x doesn't get in the way of my x-ing.
    vim.keymap.del({'x', 'o'}, 'x')
    vim.keymap.del({'x', 'o'}, 'X')

    -- Fixes leap's remapping of x in visual mode.
    visual('g', '<Plug>(leap-forward-till)')

    -- Telescope
    -- ---------------------------------------------------------------------- --

    normal(';f', ':Telescope find_files<CR>')
    normal(';g', ':Telescope live_grep<CR>')
    normal(';b', ':Telescope buffers<CR>')
    normal(';;', ':Telescope help_tags<CR>')

    -- Nvim Tree
    -- ---------------------------------------------------------------------- --

    -- normal('<C-h>', ':NvimTreeToggle<cr>')

    -- Trouble
    -- ---------------------------------------------------------------------- --

    -- Open Trouble window with `<Leader>-`
    normal('<leader>-', '<cmd>TroubleToggle<CR>')
    -- Open Trouble workspace diagnostics with `<Leader>xw`
    normal('<leader>xw', '<cmd>Trouble workspace_diagnostics<CR>')
    -- Open Trouble document diagnostics with `<Leader>xd`
    normal('<leader>xd', '<cmd>Trouble document_diagnostics<CR>')
    -- Open Trouble loclist with `<Leader>xl`
    normal('<leader>xl', '<cmd>Trouble loclist<CR>')
    -- Open Trouble LSP References of the word under the cursor with `<Leader>--`
    normal('<leader>--', '<cmd>TroubleToggle lsp_references<CR>')

    -- TO-DO normal('<leader>... '<cmd>Trouble quickfix<CR>')
    -- TO-DO normal('<leader>... '<cmd>Trouble lsp_reference<CR>')

    -- Focus
    -- ---------------------------------------------------------------------- --

    normal('<leader>h', ':FocusSplitLeft<CR>')
    normal('<leader>j', ':FocusSplitDown<CR>')
    normal('<leader>k', ':FocusSplitUp<CR>')
    normal('<leader>l', ':FocusSplitRight<CR>')

    -- Luasnip

    -- ---------------------------------------------------------------------- --

    -- ====================================================================== --
    -- TO-DO
    -- ====================================================================== --

    -- HighStr
    -- ---------------------------------------------------------------------- --

    -- visual('<F3>', ':<c-u>HSHighlight 1<CR>')
    -- visual('<F4>', ':<c-u>HSRmHighlight 1<CR>')

end
