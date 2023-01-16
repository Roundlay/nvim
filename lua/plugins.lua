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
        -- -----------------------------

        Plug('lewis6991/impatient.nvim')
        Plug('nathom/filetype.nvim')

        -- Editor
        -- -----------------------------

        Plug('unblevable/quick-scope')
        Plug('terrortylor/nvim-comment')
        Plug('ggandor/leap.nvim')
        Plug('tpope/vim-repeat')
        Plug('tpope/vim-surround')

        -- User Interface
        -- -----------------------------

        Plug('nvim-lualine/lualine.nvim')
        Plug('lukas-reineke/indent-blankline.nvim')
        -- Plug('p00f/nvim-ts-rainbow')
        -- Plug('petertriho/nvim-scrollbar')

        -- Themes
        -- -----------------------------

        -- Plug('dracula/vim', { as = 'dracula' })
        -- Plug('mvpopuk/inspired-github.vim')
        -- Plug('tomasiser/vim-code-dark')
        Plug('rebelot/kanagawa.nvim')

        -- Tools
        -- -----------------------------

        Plug('folke/trouble.nvim')
        Plug('Pocco81/auto-save.nvim')

        -- LSP & Completion
        -- -----------------------------

        Plug('neovim/nvim-lspconfig')
        Plug('williamboman/mason.nvim')
        Plug('williamboman/mason-lspconfig.nvim')
        Plug('github/copilot.vim') -- DEPS: Node.js >= 16
        Plug('neoclide/coc.nvim', { branch = 'release' }) -- DEPS: Node.js >= 14.14

        -- Language Servers & Syntax
        -- -----------------------------

        Plug('DanielGavin/ols')
        Plug('DanielGavin/odin.vim')
        Plug('simrat39/rust-tools.nvim')
        -- Plug('ap29600/tree-sitter-odin')

        -- Dependencies and Libraries
        -- -----------------------------

        Plug('nvim-treesitter/nvim-treesitter', { ['do'] = ':TSUpdate' })
        -- Plug('nvim-telescope/telescope.nvim', {['tag'] = '0.1.0'})
        Plug('nvim-treesitter/playground')
        Plug('nvim-lua/plenary.nvim')
        Plug('nvim-lua/popup.nvim')

        -- Todos
        -- -----------------------------

        -- Plug('akinsho/toggleterm.nvim', { ['tag'] = 'v2.2.1' })
        -- Plug('spywhere/tmux.nvim')

    vim.call('plug#end')

    -- Setup
    -- ------------------------------------------------------------------------

    -- Misc
    -- ---------------------------------

    -- impatient.nvim
    require('impatient')

    -- Autosave
    require('auto-save').setup({
        enabled = true,
        execution_message = {
            message = function() return ('Auto-Saved at '..vim.fn.strftime('%H:%M:%S')) end,
            dim = 0.33,
        },
        write_all_buffers = true,
    })

    -- filetype.nvim
    require('filetype').setup({
        overrides = {
            extensions = {
                odin = 'odin',
                rs = 'rust',
                py = 'python',
                ipynb = 'python',
            }
        }

    })

    -- nvim-comment
    require('nvim_comment').setup()

    -- leap.nvim
    require('leap').add_default_mappings()

    -- User Interface
    -- ---------------------------------

    -- require('scrollbar').setup({
    --     marks = {
    --         Cursor = {
    --             text = "∙",
    --             priority = 0,
    --             color = nil,
    --             cterm = nil,
    --             highlight = "Normal",
    --         }
    --     }
    -- })

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
            lualine_b = {'diff', 'diagnostics'},
            lualine_c = {{'filename', file_status = true, newfile_status = true, path = 0, shorting_target = 20, symbols = {modified = ' MODIFIED', readonly = ' READONLY', unnamed = ' UNNAMED', newfile = ' NEW FILE'}}},
            -- lualine_x = {{'fileformat', symbols = {unix = '', dos = '', mac = '', odin = '', lua = '',}}, 'filetype'},
            lualine_y = {{"os.date('%I:%M %p')"}},
            lualine_z = {{'location'}},
        },
    }

    require('indent_blankline').setup {
        char = '┃',
        char_blankline = '┃',
        -- indent_blankline_char = '┃',
        show_current_context = false,
        show_current_context_start = false,
        show_end_of_line = true,
        show_first_indent_level = true,
        show_foldtext = true,
        show_trailing_blankline_indent = true,
        strict_tabs = false,
        use_treesitter = false, -- Was causing some issues with .odin files.
        use_treesitter_scope = true,
    }

    require('trouble').setup{
        icons = false
    } -- NOTE: Disable underlines with `vim.diagnostic.config({ underline = false })`

    -- LSPs
    -- ---------------------------------

    -- Mason
    require('mason').setup()
    require('mason-lspconfig').setup()

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
        playground = {
            enable = true,
            disable = {},
            updatetime = 25,
            persist_queries = false,
            keybindings = {
                toggle_query_editor = 'o',
                toggle_hl_groups = 'i',
                toggle_injected_languages = 't',
                toggle_anonymous_nodes = 'a',
                toggle_language_display = 'I',
                focus_language = 'f',
                unfocus_language = 'F',
                update = 'R',
                goto_node = '<cr>',
                show_help = '?',
            },
        },
    }

    -- TODO
    -- local telescope = require('telescope').setup{}

    -- Rust
    -- TODO
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
    -- local on_attach = function(client, bufnr) vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc') end

    -- Odin
    if not configs.ols then
        configs.ols = {
            default_config = {
                cmd = { 'ols' },
                on_attach = function(_, bufnr)
                end,
                filetypes = { 'odin' },
                root_dir = util.root_pattern('ols.json'),
                settings = {},
            }
        }
    end

    configs.ols.setup{}

    -- Treesitter Odin
    -- local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
    -- parser_config.odin = {
    --     install_info = {
    --         -- Files in the queries subdirectory are symlinked to the runtime queries/odin directory.
    --         url = 'C:/Users/Christopher/.config/nvim/plugs/tree-sitter-odin',
    --         files = { 'src/parser.c' },
    --     },
    --     filetype = 'odin',
    -- }

    -- Pyright
    require('lspconfig').pyright.setup({})

    -- Kanagawa
    require('kanagawa').setup({
        undercurl = true,
        typeStyle = {bold = true},
        commentStyle = { italic = false },
        terminalColors = true,
        dimInactive = false,
    })

    vim.cmd("colorscheme kanagawa")

    vim.api.nvim_set_hl(0, 'IndentBlanklineChar', {foreground = '#2e303e'}) -- Indent blankline colour

end
