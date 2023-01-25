-- KEYBINDINGS

-- -----------------------------------------------------------------------------

-- `opts` Helpers
-- `noremap`: Ensures that your mapping will always take precedence over any other attempts to remap it. Note: this only applies to the mode defined in the mapping.
-- `silent`: This tells Vim to not display any error messages if the key mapping fails.
-- `expr`: This tells Vim to execute the right-hand side of the mapping as an expression. This means that the right-hand side can be any valid Vimscript expression, and it will be evaluated and executed when the key sequence is pressed. *Todo This is useful for mapping keys to functions that return a string.
-- `replace_keycodes`: This tells Vim to not replace key codes in the key sequence with the corresponding characters. This can be useful in situations where you want to map a key sequence that includes special key codes, such as <C-a> for Control+a.

-- -----------------------------------------------------------------------------

-- Helper Functions

function map(mode, new, old, opts)
    -- map("n", ";f", ":Telescope find_files<CR>", {expr = true})
    local default_opts = {}
    if opts then
        options = vim.tbl_extend("force", default_opts, opts) -- Merges the `default_opts` and `opts` tables
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

-- -----------------------------------------------------------------------------

if (vim.g.vscode) then

    -- VISUAL STUDIO CODE
    
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

    -- NEOVIM

    -- Leader Key
    vim.g.mapleader = ' ' -- `vim.g.mapleader = '<Space>'` doesn't work.

    -- Esc Key
    -- normal('<C-j>', '<esc>')
    -- visual('<C-j>', '<esc>')
    -- insert('<C-j>', '<esc>')
    -- normal('<leader-o>', 'o<Esc>^D0')

    normal('J', '}') -- Jump paragraph backwards in normal mode.
    normal('K', '{') -- Jump paragraph forwards in normal mode.
    normal('L', '$') -- Jump to the end of the active line.
    normal('H', '_') -- Jump to the beginning of the active line.
    normal('<n>', '<C-v>') -- WIN: Fixes paste overlap w/ Visual Command Mode.
    visual('J', '}') -- Jump paragraph backwards in visual mode.
    visual('K', '{') -- Jump paragraph forwards in visual mode.
    visual('p', 'pgvy') -- Paste, reselect the original selection with `gv`, and re-yank the selection.
    
    -- Copy to System Clipboard
    normal('<leader>y', '"+y') -- Normal Mode: Copy to clipboard
    normal('<leader>yy', '"+yy') -- Normal Mode: Copy the active line to the clipboard.
    normal('<leader>Y', '"+Y') -- Normal Mode: Copy the active line to the clipboard starting from the cursor.
    visual('<leader>y', '"+y') -- Visual Mode: Copy to clipboard

    -- Paste from System Clipboard
    normal('<leader>p', '"+p') -- Normal Mode: Paste from clipboard
    normal('<leader>P', '"+P') -- Normal Mode: Paste from clipboard
    visual('<leader>p', '"+p') -- Visual Mode: Paste from clipboard
    visual('<leader>P', '"+P') -- Visual Mode: Paste from clipboard

    -- CoC
    function _G.check_back_space()
        local col = vim.fn.col('.') - 1
        return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
    end

    local coc_opts = {silent = true, noremap = true, expr = true, replace_keycodes = false}

    -- Tab Completion
    -- This seems irrelevant... I can just space out of the selection...
    map('i', '<CR>', [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], coc_opts)

    normal('gd', '<Plug>(coc-definition)')
    normal('[g', '<Plug>(coc-diagnostic-prev)')
    normal(']g', '<Plug>(coc-diagnostic-next)')

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
    -- Leap is a died-in-the-wool never-x-er so I'm deleting x here so that Leap's
    -- overriding of x doesn't get in the way of my x-ing.
    vim.keymap.del({'x', 'o'}, 'x')
    vim.keymap.del({'x', 'o'}, 'X')
    visual('g', '<Plug>(leap-forward-till)') -- Fixes leap's remapping of x in visual mode.

    -- ols Formatting
    -- au BufNewFile,BufRead *.odin map <C-P> :w<Return>:%!odinfmt %<Return>
    vim.cmd [[ au BufNewFile,BufRead *.odin map=<C-'> :w<Return>:%!odinfmt %<Return> ]]

    -- nvim-tree.lua
    normal('<C-h>', ':NvimTreeToggle<cr>')

    -- TO-DO

    -- HighStr
    -- visual('<F3>', ':<c-u>HSHighlight 1<CR>')
    -- visual('<F4>', ':<c-u>HSRmHighlight 1<CR>')

    -- Trouble
    normal('<leader>-', '<cmd>Trouble<CR>')
    normal('<leader>xw', '<cmd>Trouble workspace_diagnostics<CR>')
    normal('<leader>xd', '<cmd>Trouble document_diagnostics<CR>')
    normal('<leader>xl', '<cmd>Trouble loclist<CR>')
    -- TO-DO normal('<leader>... '<cmd>Trouble quickfix<CR>')
    -- TO-DO normal('<leader>... '<cmd>Trouble lsp_reference<CR>')

    -- Toggle Term
    -- TO-DO Input mode not working as desired.
    -- no-rmal('C-\\', '')
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
    -- normal(';f', ':Telescope find_files<CR>')
    -- normal(';g', ':Telescope live_grep<CR>')
    -- normal(';b', ':Telescope buffers<CR>')
    -- normal(';;', ':Telescope help_tags<CR>')

end
