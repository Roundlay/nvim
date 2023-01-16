-- Keybindings
-- ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

-- local map = vim.api.nvim_set_keymap
-- map('i', '<c-j>', '<esc>')
-- map('n', 'J', '}')

-- function mapper(mode, lhs, rhs, opts)
--     local options = {noremap = true}
--     if opts then
--         options = vim.tbl_extend("force", options, opts)
--     end
--     vim.api.nvim_set_keymap(mode, lhs, rhs, options)
-- end
-- mapper("n", ";f", ":Telescope find_files<CR>", {silent = true})

-- ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

-- Helpers
-- ―――――――

function map(mode, new, old)
    vim.api.nvim_set_keymap(mode, new, old, {noremap=true, silent=true})
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

-- ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

if (vim.g.vscode) then

    -- Visual Studio Code
    -- ―――――――――――――――――――――――――――――――――
    
    -- TODO: Leader key doesn't seem to work in Code.
    -- vim.g.mapleader = ','

    normal('J', '}') -- Jump n paragraphs backwards.
    normal('K', '{') -- Jump n paragraphs forwards.
    normal('L', '$') -- Jump to the end of the active line.
    normal('H', '_') -- Jump to the beginning of the active line.

    visual('J', '}') -- Jump n paragraphs backwards in visual mode.
    visual('K', '{') -- Jump n paragraphs forwards in visual mode.

    normal('<C-j>', '<esc>')
    visual('<C-j>', '<esc>')
    insert('<C-j>', '<esc>')

    -- normal('<n>', '<C-v>') -- WIN: Fixes paste overlap w/ Visual Command Mode.

else

    -- Neovim
    
    -- Leader Key
    vim.g.mapleader = ' ' -- `vim.g.mapleader = '<Space>'` doesn't work.

    -- Remap Esc Key
    -- normal('<C-j>', '<esc>')
    -- visual('<C-j>', '<esc>')
    -- insert('<C-j>', '<esc>')

    normal('J', '}') -- Jump paragraph backwards in normal mode.
    normal('K', '{') -- Jump paragraph forwards in normal mode.
    normal('L', '$') -- Jump to the end of the active line.
    normal('H', '_') -- Jump to the beginning of the active line.
    normal('<n>', '<C-v>') -- WIN: Fixes paste overlap w/ Visual Command Mode.

    visual('J', '}') -- Jump paragraph backwards in visual mode.
    visual('K', '{') -- Jump paragraph forwards in visual mode.
    
    -- TODO What's the difference between these?
    normal('<leader>y', '"+y') -- Copy to Clipboard
    visual('<leader>y', '"+y') -- Copy to Clipboard
    -- normal('<leader>yy', '"+yy') -- Copy the active line to the clipboard.

    normal('<leader>p', '"+p') -- Paste from Clipboard
    normal('<leader>P', '"+P') -- Paste from Clipboard
    visual('<leader>p', '"+p') -- Paste from Clipboard
    visual('<leader>P', '"+P') -- Paste from Clipboard

    -- OLS Formatter
    -- -------------------------------------------------------------------------
    -- au BufNewFile,BufRead *.odin map <C-P> :w<Return>:%!odinfmt %<Return>
    vim.cmd [[ au BufNewFile,BufRead *.odin map=<C-P> :w<Return>:%!odinfmt %<Return> ]]

    -- CoC
    -- -------------------------------------------------------------------------
    normal('gd', '<Plug>(coc-definition)')
    normal('[g', '<Plug>(coc-diagnostic-prev)')
    normal(']g', '<Plug>(coc-diagnostic-next)')
    insert('<c-space>', 'coc#refresh()')

    function _G.show_docs()
        local cw = vim.fn.expand('<cword>')
        if vim.fn.index({'vim', 'help'}, vim.bo.filetype) >= 0 then
            vim.api.nvim_command('h ' .. cw)
        elseif vim.api.nvim_eval('coc#rpc#ready()') then
            vim.fn.CocActionAsync('doHover')
        else
            vim.api.nvim_command('!' .. vim.o.keywordprg .. ' ' .. cw)
        end
    end
    normal('<C-k>', '<cmd>lua show_docs()<CR>')

    -- Leap
    -- -------------------------------------------------------------------------
    visual('g', '<Plug>(leap-forward-till)') -- Fixes leap's remapping of x in visual mode.

    -- HighStr
    -- -------------------------------------------------------------------------
    -- visual('<F3>', ':<c-u>HSHighlight 1<CR>')
    -- visual('<F4>', ':<c-u>HSRmHighlight 1<CR>')

    -- Trouble
    -- -------------------------------------------------------------------------
    normal('<leader>-', '<cmd>Trouble<CR>')
    -- normal('<leader>xw', '<cmd>Trouble workspace_diagnostics<CR>')
    -- normal('<leader>xd', '<cmd>Trouble document_diagnostics<CR>')
    -- normal('<leader>xl', '<cmd>Trouble loclist<CR>')
    -- TODO normal('<leader>... '<cmd>Trouble quickfix<CR>')
    -- TODO normal('<leader>... '<cmd>Trouble lsp_reference<CR>')

    -- Toggle Term
    -- -------------------------------------------------------------------------
    -- TODO Input mode not working as desired.
    -- normal('C-\\', '')
    -- function _G.set_terminal_keymaps()
    --     local opts = {buffer = 0}
    --     vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
    --     vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
    --     vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
    --     vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
    --     vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
    --     vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
    -- end

    -- Telescope
    -- ―――――――――――――――――――――――――――――――――    
    -- normal(';f', ':Telescope find_files<CR>')
    -- normal(';g', ':Telescope live_grep<CR>')
    -- normal(';b', ':Telescope buffers<CR>')
    -- normal(';;', ':Telescope help_tags<CR>')

end
