-- Guide to writing init.vim in lua: https://dev.to/vonheikemen/neovim-using-vim-plug-in-lua-3oom
-- https://youtu.be/Ku-m7eEbWas

local Plug = vim.fn['plug#']

if (vim.g.vscode) then

    vim.call('plug#begin', '~/.config/nvim/plugs')

        Plug('justinmk/vim-sneak')
        Plug('unblevable/quick-scope')

    vim.call('plug#end')

else

    vim.call('plug#begin', '~/.config/nvim/plugs')

        -- Misc

        Plug('lewis6991/impatient.nvim')
        Plug('nathom/filetype.nvim')
        Plug('Pocco81/auto-save.nvim')

        -- Editing & Navigation

        Plug('numToStr/Comment.nvim')
        -- Plug('terrortylor/nvim-comment')
        -- Plug('tpope/vim-repeat')
        Plug('tpope/vim-surround') -- TODO Learn it
        Plug('unblevable/quick-scope')
        Plug('ggandor/leap.nvim')

        -- User Interface

        Plug('nvim-tree/nvim-tree.lua')
        Plug('lukas-reineke/indent-blankline.nvim')
        Plug('nvim-lualine/lualine.nvim')

        -- Themes

        Plug('rebelot/kanagawa.nvim')
        -- Plug('dracula/vim', { as = 'dracula' })
        -- Plug('mvpopuk/inspired-github.vim')
        -- Plug('tomasiser/vim-code-dark')

        -- Language Support

        Plug('neovim/nvim-lspconfig')
        Plug('williamboman/mason.nvim')
        Plug('williamboman/mason-lspconfig.nvim')
        Plug('github/copilot.vim') -- DEPS: Node.js >= 16
        Plug('neoclide/coc.nvim', { branch = 'release' }) -- DEPS: Node.js >= 14.14
        Plug('folke/trouble.nvim')
        Plug('DanielGavin/ols')
        Plug('DanielGavin/odin.vim')
        -- Plug('simrat39/rust-tools.nvim')
        -- Plug('ap29600/tree-sitter-odin')

        -- Dependencies

        Plug('nvim-treesitter/nvim-treesitter', { ['do'] = ':TSUpdate' })
        Plug('nvim-treesitter/playground')
        Plug('nvim-lua/plenary.nvim')
        Plug('nvim-lua/popup.nvim')

        -- Todos

        -- Plug('junegunn/fzf', { ['do'] = ':fzf#install()' })
        -- Plug('junegunn/fzf.vim')
        -- Plug('nvim-telescope/telescope.nvim', {['tag'] = '0.1.0'})
        -- Plug('akinsho/toggleterm.nvim', { ['tag'] = 'v2.2.1' })
        -- Plug('spywhere/tmux.nvim')

    vim.call('plug#end')

    -- ---------------------------------------------------------------------- --

    -- Impatient

    require('impatient')

    -- ---------------------------------------------------------------------- --

    -- Filetype

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

    -- ---------------------------------------------------------------------- --

    -- Nvim Tree

    local lib = require('nvim-tree.lib')
    local view = require('nvim-tree.view')
    
    local function collapse_all()
        require("nvim-tree.actions.tree-modifiers.collapse-all").fn()
    end

    local function edit_or_open()
        local action = "edit"
        local node = lib.get_node_at_cursor()
        if node.link_to and not node.nodes then
            require('nvim-tree.actions.node.open-file').fn(action, node.link_to)
            view.close() -- Close the tree if file was opened
        elseif node.nodes ~= nil then
            lib.expand_or_collapse(node)
        else
            require('nvim-tree.actions.node.open-file').fn(action, node.absolute_path)
            view.close() -- Close the tree if file was opened
        end
    end

    -- TODO: fix opening and closing with L. L should preview in a split then close again when L is pressed a second time.
    -- vsplitpreview = false
    local function vsplit_preview()
        local action = "vsplit"
        local node = lib.get_node_at_cursor()
        if node.link_to and not node.nodes and not vsplitpreview then
            require('nvim-tree.actions.node.open-file').fn(action, node.link_to)
            vsplitpreview = true
        elseif node.nodes ~= nil then
            lib.expand_or_collapse(node)
        -- elseif vsplitpreview then
        --     require('nvim-tree.actions.node.close-file').fn(action, node.absolute_path)
        --     vsplitpreview = false
        else
            require('nvim-tree.actions.node.open-file').fn(action, node.absolute_path)
        end
        view.focus()
    end

    require('nvim-tree').setup({
        sort_by = 'type',
        view = {
            cursorline = false,
            signcolumn = "no",
            mappings = {
                custom_only = false,
                list = {
                    { key = "l", action = "edit", action_cb = edit_or_open },
                    { key = "L", action = "vsplit_preview", action_cb = vsplit_preview },
                    { key = "h", action = "close_node" },
                    { key = "H", action = "collapse_all", action_cb = collapse_all }
                }
            },
        },
        actions = {
            open_file = {
                quit_on_open = false
            }
        },
        renderer = {
            highlight_opened_files = "all",
            highlight_modified = "all",
            icons = {
                modified_placement = "before",
                padding = "",
                show = {
                    file = true,
                    folder = false,
                    folder_arrow = true,
                    git = false,
                    modified = false,
                },
                glyphs = {
                    default = "",
                    symlink = "◀",
                    bookmark = "@",
                    modified = "#",
                    folder = {
                        arrow_closed = "▶",
                        arrow_open = "▼",
                        default = "",
                        open = "",
                        empty = "▷",
                        empty_open = "▽",
                        symlink = "◀",
                        symlink_open = "◁",
                    },
                },
            },
        },
    })

    -- require('nvim-tree').setup(nvim_tree_config)

    -- Lualine
    -- ---------------------------------------------------------------------- --

    local file_buffer_name = {'filename', file_status = true, newfile_status = true, path = 0, shorting_target = 10, symbols = {modified = 'MO', readonly = 'RO', unnamed = 'UN', newfile = 'NF'}}
    local nvimtree_buffer_name = {symbols = {modified = 'MO', readonly = 'RO', unnamed = 'UN', newfile = 'NF'}}

    require('lualine').setup {
        options = {
            always_divide_middle = true,
            component_separators = { left = '', right = '' },
            section_separators = { left = '', right = '' },
            globalstatus = true,
            icons_enabled = false,
            refresh = {
                statusline = 10,
                tabline = 500,
                winbar = 500,
            },
            extensions = {'nvim-tree'},
            -- disabled_filetypes = { 'NvimTree' },
            -- theme = 'dracula',
        }, 
        sections = {
            lualine_a = {{'mode', show_modified_status = true, mode = 2},},
            lualine_b = {'diff', 'diagnostics'},
            lualine_c = {file_buffer_name},
            lualine_x = {{'fileformat', symbols = {unix = 'UNIX', dos = 'DOS', mac = 'Mac', odin = 'ODIN', lua = 'LUA'}}, 'filetype'},
            lualine_y = {{"os.date('%I:%M:%S %p', os.time())"}},
            lualine_z = {{'location'}},
        },  
        -- tabline = {
        --     lualine_a = {'tabs'},
        --     lualine_b = {'buffers'},
        --     lualine_c = {''},
        --     lualine_x = {},
        --     lualine_y = {},
        --     lualine_z = {}
        -- },
        -- winbar = {
        --     lualine_a = {{'buffers', mode = 2, symbols = {modified = '', readonly = '-', unnamed = '~', newfile = ''}}},
        --     lualine_b = {''},
        --     lualine_c = {''},
        --     lualine_x = {},
        --     lualine_y = {{'windows'}},
        --     lualine_z = {{'searchcount'}}
        -- },
        -- inactive_winbar = {
        --     lualine_a = {'buffers'},
        --     lualine_b = {''},
        --     lualine_c = {''},
        --     lualine_x = {},
        --     lualine_y = {},
        --     lualine_z = {}
        -- }
    }

    -- Close nvim-tree if it's the last open window.
    vim.cmd([[ autocmd BufEnter * ++nested if winnr("$") == 1 && bufname() == "NvimTree_" . tabpagenr() | quit | endif ]])

    -- Turn off lualine inside nvim-tree
    -- vim.cmd [[ au BufEnter,BufWinEnter,WinEnter,CmdwinEnter * if bufname('%') == "NvimTree_1" | set bufname('%') == '' | endif ]]

    -- Trigger rerender of status line every second for clock
    if _G.Statusline_timer == nil then
        _G.Statusline_timer = vim.loop.new_timer()
    else
        _G.Statusline_timer:stop()
    end
    _G.Statusline_timer:start(0, 1000, vim.schedule_wrap(
    function() vim.api.nvim_command('redrawstatus') end))


    -- autosave
    require('auto-save').setup({
        enabled = true,
        execution_message = {
            message = function() return ('Auto-Saved at '..vim.fn.strftime('%H:%M:%S')) end,
            dim = 0.33,
        },
        write_all_buffers = true,
    })

    -- Comment.nvim
    require('Comment').setup()
    local ft = require('Comment.ft')
    ft.odin = {'//%s', '/*%s*/'}


    -- leap.nvim
    require('leap').add_default_mappings()


    -- indent-blankline.nvim
    require('indent_blankline').setup {
        char = '┃',
        char_blankline = '┃',
        show_current_context = false,
        show_current_context_start = false,
        show_end_of_line = false,
        show_first_indent_level = true,
        show_foldtext = true,
        show_trailing_blankline_indent = false,
        strict_tabs = false,
        use_treesitter = true, -- Was causing some issues with .odin files.
        use_treesitter_scope = true,
    }

    -- trouble.nvim
    require('trouble').setup{
        icons = false
    } -- NOTE: Disable underlines with `vim.diagnostic.config({ underline = false })`

    -- -------------------------------------------------------------------------
    -- LSPs & Syntax
    -- -------------------------------------------------------------------------

    -- TODO
    -- local telescope = require('telescope').setup{}

    local util = require('lspconfig.util')
    local configs = require('lspconfig.configs')
    -- local on_attach = function(client, bufnr) vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc') end

    -- mason.nvim
    require('mason').setup()
    require('mason-lspconfig').setup()

    -- nvim-treesitter 
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

    require('lspconfig').pyright.setup({})

    -- Rust
    -- require('rust-tools').setup({
    --     server = {
    --         on_attach = function(_, bufnr)
    --             -- Hover actions
    --             vim.keymap.set('n', '<C-space>', rt.hover_actions.hover_actions, { buffer = bufnr })
    --             -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-space>', rt.hover_actions.hover_actions, {buffer = bufnr})
    --             -- Code action groups
    --             vim.keymap.set('n', '<leader>a', rt.code_action_group.code_action_group, { buffer = bufnr })
    --         end,
    --     },
    -- })

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

    -- Treesitter Odin ------------------------------------------------------ --

    -- local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
    -- parser_config.odin = {
    --     install_info = {
    --         -- Files in the queries subdirectory are symlinked to the runtime queries/odin directory.
    --         url = 'C:/Users/Christopher/.config/nvim/plugs/tree-sitter-odin',
    --         files = { 'src/parser.c' },
    --     },
    --     filetype = 'odin',
    -- }

    -- THEMES

    -- Kanagawa Theme

    local kanagawa = require("kanagawa.colors").setup()

    -- NOTE: In case you ever want to override anything.
    -- local colours = {
    --     sumiInk1 = '#1F1F28',
    -- }
    -- local overrides = {
    --     myhighlightgroup = {fg = kanagawa.waveRed, bg = "AAAAAA", underline = true, bold = true, guisp = "blue"},
    -- }

    require('kanagawa').setup({
        colors = kanagawa,
        undercurl = true,
        typeStyle = { bold = true },
        commentStyle = { italic = false },
        terminalColors = true,
        globalStatus = true,
        dimInactive = true,
    })

    vim.cmd("colorscheme kanagawa")

    -- HIGHLIGHTS
    -- Highlights get called from scripts.lua so that they're not overwritten by anything else.

end
