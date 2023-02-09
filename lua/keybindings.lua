-- KEYBINDINGS

-- `opts` Helpers
-- `noremap`: Ensures that your mapping will always take precedence over any other attempts to remap it. Note: this only applies to the mode defined in the mapping.
-- `silent`: This tells Vim to not display any error messages if the key mapping fails.
-- `expr`: This tells Vim to execute the right-hand side of the mapping as an expression. This means that the right-hand side can be any valid Vimscript expression, and it will be evaluated and executed when the key sequence is pressed. *Todo This is useful for mapping keys to functions that return a string.
-- `replace_keycodes`: This tells Vim to not replace key codes in the key sequence with the corresponding characters. This can be useful in situations where you want to map a key sequence that includes special key codes, such as <C-a> for Control+a.

-- ------------------------------------------------------------------------  --

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

function terminal(new, old)
    vim.api.nvim_set_keymap('t', new, old, {buffer = 0})
end

-- -------------------------------------------------------------------------- --

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

    -- normal('<n>', '<C-v>') -- WIN: Fixes paste overlap w/ Visual Command Mode.

else

    -- ---------------------------------------------------------------------- --
    -- NEOVIM
    -- ---------------------------------------------------------------------- --

    -- Huh?
    -- ---------------------------------------------------------------------- --

    normal('<n>', '<C-v>') -- WIN: Fixes paste overlap w/ Visual Command Mode.

    -- Leader Key
    -- ---------------------------------------------------------------------- --

    -- normal(' ', '<Nop>')
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

    -- Yank & Paste
    -- ---------------------------------------------------------------------- --

    -- Paste & Re-yank Original Selection

    visual('p', 'pgvy')

    -- Copy to System Clipboard

    normal('<leader>y', '"+y')
    normal('<leader>yy', '"+yy')
    normal('<leader>Y', '"+Y')
    visual('<leader>y', '"+y')

    -- Paste from System Clipboard

    normal('<leader>p', '"+p')
    normal('<leader>P', '"+P')
    visual('<leader>p', '"+p')
    visual('<leader>P', '"+P')

    -- PLUGINS
    -- ---------------------------------------------------------------------- --

    -- CoC
    -- ---------------------------------------------------------------------- --

    -- function _G.check_back_space()
    --     local col = vim.fn.col('.') - 1
    --     return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
    -- end

    local coc_opts = {
        silent=true,
        noremap=true,
        expr=true, 
        replace_keycodes=false
    }
 
    map('i', '<CR>', [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], coc_opts) -- This seems irrelevant... I can just space out of the selection...
    normal('gd', '<Plug>(coc-definition)') -- CoC: Go to definition
    -- normal('[g', '<Plug>(coc-diagnostic-prev)') -- CoC: Go to previous diagnostic
    -- normal(']g', '<Plug>(coc-diagnostic-next)') -- CoC: Go to next diagnostic


    -- Your language server must support hover for this to work.

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
    normal('<leader>d', '<cmd>lua show_docs()<CR>')

    -- Leap
    -- ---------------------------------------------------------------------- --

    -- Leap is a died-in-the-wool never-x-er so I'm deleting x here so that
    -- Leap's overriding of x doesn't get in the way of my x-ing.

    vim.keymap.del({'x', 'o'}, 'x')
    vim.keymap.del({'x', 'o'}, 'X')

    visual('g', '<Plug>(leap-forward-till)') -- Fixes leap's remapping of x in visual mode.

    -- Nvim Tree
    -- ---------------------------------------------------------------------- --

    -- normal('<C-h>', ':NvimTreeToggle<cr>')

    -- Trouble
    -- ---------------------------------------------------------------------- --

    -- Open Trouble window with `<Leader>-`
    normal('<leader>-', '<cmd>Trouble<CR>')
    -- Open Trouble workspace diagnostics with `<Leader>xw`
    normal('<leader>xw', '<cmd>Trouble workspace_diagnostics<CR>')
    -- Open Trouble document diagnostics with `<Leader>xd`
    normal('<leader>xd', '<cmd>Trouble document_diagnostics<CR>')
    -- Open Trouble loclist with `<Leader>xl`
    normal('<leader>xl', '<cmd>Trouble loclist<CR>')

    -- TO-DO normal('<leader>... '<cmd>Trouble quickfix<CR>')
    -- TO-DO normal('<leader>... '<cmd>Trouble lsp_reference<CR>')

    -- Tabline
    -- ---------------------------------------------------------------------- --

    -- Move to the next buffer in the tabline with `tn`
    -- normal('tn', '<cmd>TablineBufferNext<CR>')

    -- Harpoon
    -- ---------------------------------------------------------------------- --

    local harpoon_mark = require("harpoon.mark")
    local harpoon_ui = require("harpoon.ui")

    vim.keymap.set("n", "<leader>a", harpoon_mark.add_file)
    vim.keymap.set("n", "<C-e>", harpoon_ui.toggle_quick_menu)

    vim.keymap.set("n", "<C-h>", function() harpoon_ui.nav_file(1) end)
    vim.keymap.set("n", "<C-t>", function() harpoon_ui.nav_file(2) end)
    vim.keymap.set("n", "<C-n>", function() harpoon_ui.nav_file(3) end)
    vim.keymap.set("n", "<C-s>", function() harpoon_ui.nav_file(4) end)

    -- TO-DO
    -- ---------------------------------------------------------------------- --

    -- HighStr
    -- ---------------------------------------------------------------------- --

    -- visual('<F3>', ':<c-u>HSHighlight 1<CR>')
    -- visual('<F4>', ':<c-u>HSRmHighlight 1<CR>')

    -- Telescope
    -- ---------------------------------------------------------------------- --

    -- normal(';f', ':Telescope find_files<CR>')
    -- normal(';g', ':Telescope live_grep<CR>')
    -- normal(';b', ':Telescope buffers<CR>')
    -- normal(';;', ':Telescope help_tags<CR>')

end
