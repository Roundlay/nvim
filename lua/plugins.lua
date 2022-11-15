-- Guide to writing init.vim in lua: https://dev.to/vonheikemen/neovim-using-vim-plug-in-lua-3oom
-- https://youtu.be/Ku-m7eEbWas

local Plug = vim.fn['plug#']

if (vim.g.vscode) then

    -- CODE

    vim.call('plug#begin', '~/.config/nvim/plugs')

        Plug('justinmk/vim-sneak')
        Plug('unblevable/quick-scope')

    vim.call('plug#end')

else

    -- NEOVIM

    vim.call('plug#begin', '~/.config/nvim/plugs')

        -- Misc.
        -- ―――――

        Plug('lewis6991/impatient.nvim')
        Plug('nathom/filetype.nvim')

        -- Editor
        -- ――――――

        Plug('unblevable/quick-scope')
        Plug('terrortylor/nvim-comment')
        Plug('ggandor/leap.nvim')
        Plug('tpope/vim-repeat')
        Plug('tpope/vim-surround')

        -- User Interface
        -- ――――――――――――――

        Plug('nvim-lualine/lualine.nvim')
        Plug('lukas-reineke/indent-blankline.nvim')
        Plug('gorbit99/codewindow.nvim')
        -- Plug('p00f/nvim-ts-rainbow')

        -- Themes
        -- ――――――

        -- Plug('dracula/vim', { as = 'dracula' })
        -- Plug('mvpopuk/inspired-github.vim')
        -- Plug('tomasiser/vim-code-dark')
        Plug('rebelot/kanagawa.nvim')

        -- Tools
        -- ―――――

        Plug('folke/trouble.nvim')
        Plug('Pocco81/auto-save.nvim')

        -- LSP & Completion
        -- ――――――――――――――――

        Plug('neovim/nvim-lspconfig')
        Plug('williamboman/mason.nvim')
        Plug('williamboman/mason-lspconfig.nvim')
        Plug('github/copilot.vim') -- DEPS: Node.js >= 16
        Plug('neoclide/coc.nvim', { branch = 'release' }) -- DEPS: Node.js >= 14.14

        -- Language Servers & Syntax
        -- ―――――――――――――――――――――――――

        Plug('DanielGavin/ols')
        Plug('ap29600/tree-sitter-odin')
        Plug('simrat39/rust-tools.nvim')

        -- Dependencies and Libraries
        -- ――――――――――――――――――――――――――

        Plug('nvim-treesitter/nvim-treesitter', { ['do'] = ':TSUpdate' })
        -- Plug('nvim-telescope/telescope.nvim', {['tag'] = '0.1.0'})
        Plug('nvim-lua/plenary.nvim')
        Plug('nvim-lua/popup.nvim')

        -- Todos
        -- ―――――

        -- Plug('akinsho/toggleterm.nvim', { ['tag'] = 'v2.2.1' })
        -- Plug('spywhere/tmux.nvim')

    vim.call('plug#end')

    -- 

    --  SETUP 

    -- Misc.
    -- ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    require('impatient')

    require('filetype').setup({
        overrides = {
            extensions = {
                odin = 'odin',
                rs = 'rust'
            }
        }

    })

    -- Editor
    -- ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    -- Nvim Comment
    require('nvim_comment').setup()

    -- Leap
    require('leap').add_default_mappings()

    -- User Interface

    require('lualine').setup {
        options = {
            always_divide_middle = false,
            component_separators = { left = ' ', right = ' ' },
            section_separators = { left = '', right = '' },
            globalstatus = false,
            icons_enabled = false,
            -- extensions = {'toggleterm'},
            -- theme = 'dracula',
        },
        sections = {
            lualine_a = {{'mode', show_modified_status = true, mode = 2}},
            lualine_b = {'branch', 'diff', 'diagnostics'},
            lualine_c = {{'filename', file_status = true, newfile_status = true, path = 0, shorting_target = 20, symbols = {modified = ' MODIFIED', readonly = ' READONLY', unnamed = ' UNNAMED', newfile = ' NEW FILE'}}},
            -- lualine_x = {{'fileformat', symbols = {unix = '', dos = '', mac = '', odin = '', lua = '',}}, 'filetype'},
            lualine_y = {{"os.date('%I:%M %p')"}},
            lualine_z = {{'location'}},
        },
    }

    require('indent_blankline').setup {
        char = '┃',
        char_blankline = '┃',
        show_current_context = false,
        show_current_context_start = false,
        show_end_of_line = true,
        show_first_indent_level = true,
        show_foldtext = true,
        show_trailing_blankline_indent = true,
        strict_tabs = true,
        use_treesitter = false, -- Was causing some issues with .odin files.
        use_treesitter_scope = true,
    }

    require('trouble').setup{
        icons = false
    } -- NOTE: Disable underlines with `vim.diagnostic.config({ underline = false })`

    -- Mason
    require('mason').setup()
    require('mason-lspconfig').setup()

    -- Autosave
    require('auto-save').setup({
        enabled = true,
        execution_message = {
            message = function() return ('Auto-Saved at '..vim.fn.strftime('%H:%M:%S')) end,
            dim = 0.25,
        },
        write_all_buffers = true,
    })

    -- Treesitter
    require('nvim-treesitter.configs').setup {
        ensure_installed = 'all', -- Only use parsers that are maintained.
        auto_install = true,
        highlight = {
            enable = true,
        },
        indent = {
            enable = false -- Experimental and broke indentation in Odin.
        },
        rainbow = {
            enable = false,
            extended_mode = true,
            max_file_lines = nil,
            colors = {
            },
        },
    }

    -- local telescope = require('telescope').setup{}

    -- Rust

    require('rust-tools').setup({
        server = {
            on_attach = function(_, bufnr)
                -- Hover actions
                vim.keymap.set('n', '<C-space>', rt.hover_actions.hover_actions, { buffer = bufnr })
                -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-space>', rt.hover_actions.hover_actions, {buffer = bufnr})
                -- Code action groups
                vim.keymap.set('n', '<leader>a', rt.code_action_group.code_action_group, { buffer = bufnr })
            end,
        },
    })

    local util = require('lspconfig.util')
    local configs = require('lspconfig.configs')
    local on_attach = function(client, bufnr) vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc') end

    -- Odin

    if not configs.ols then
        configs.ols = {
            default_config = {
                cmd = { 'ols' },
                -- on_attach = on_attach,
                on_attach = function(_, bufnr)
                    -- vim.keymap.set('n', '<C-space>', rt.hover_actions.hover_actions, { buffer = bufnr })
                    -- vim.keymap.set('n', '<leader>a', rt.code_action_group.code_action_group, { buffer = bufnr })
                end,
                filetypes = { 'odin' },
                root_dir = util.root_pattern('ols.json'),
                settings = {},
            }
        }
    end

    configs.ols.setup{}

    local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
    parser_config.odin = {
        install_info = {
            -- Files in the queries subdirectory are symlinked to the runtime queries/odin directory.
            url = 'C:/Users/Christopher/.config/nvim/plugs/tree-sitter-odin',
            files = { 'src/parser.c' },
        },
        filetype = 'odin',
    }

    require('kanagawa').setup({
        undercurl = true,
        typeStyle = {bold = true},
        commentStyle = { italic = false },
        terminalColors = true,
        dimInactive = false,
    })


    -- TODO

    -- Toggle Term
    -- require('toggleterm').setup {
    --     close_on_exit = true,
    --     direction = 'horizontal',
    --     hide_numbers = true,
    --     open_mapping = [[<C-t>]],
    --     shade_terminals = false,
    --     start_in_insert = true,
    --     terminal_mappings = true,
    -- }

    -- Tmux
    -- require('tmux').start()
    -- {
    --     config = function ()
    --     local tmux = require('tmux')
    --     local cmds = require('tmux.commands')
    --     -- Configuration goes here.
    --     -- Bindings
    --     -- tmux.prefix('<C-a>')
    --     -- Custom Bindings
    --     -- tmux.bind('|', cmds.split_window {'v'})
    --     -- tmux.bind('-', cmds.split_window {'h'})
    --     tmux.start()
    -- end
    -- }

    -- Codewindow
    -- local codewindow = require('codewindow')
    --
    -- codewindow.setup({
    --     width_multiplier = 1,
    --     show_cursor = true,
    -- })
    --
    -- codewindow.apply_default_keybinds()

    vim.cmd("colorscheme kanagawa")

    vim.api.nvim_set_hl(0, 'IndentBlanklineChar', {foreground = '#2e303e'}) -- Indent blankline colour

end
