-- plugins.lua
-- -------------------------------------------------------------------------- --

local scripts = require("scripts")
local Plug = vim.fn["plug#"]

if (vim.g.vscode) then

    -- ====================================================================== --
    -- Visual Studio Code
    -- ====================================================================== --

    vim.call("plug#begin", "~/.config/nvim/plugs")

        Plug("justinmk/vim-sneak")
        Plug("unblevable/quick-scope")

    vim.call("plug#end")

else

    -- ====================================================================== --
    -- Neovim
    -- ====================================================================== --

    vim.call("plug#begin", "~/.config/nvim/plugs")

        -- Meta
        -- ------------------------------------------------------------------ --

        Plug("lewis6991/impatient.nvim")
        -- Plug("nathom/filetype.nvim")
        Plug("Pocco81/auto-save.nvim")

        -- Editor
        -- ------------------------------------------------------------------ --

        Plug("ggandor/leap.nvim")
        Plug("numToStr/Comment.nvim")
        Plug("unblevable/quick-scope")
        Plug("echasnovski/mini.align")
        Plug("echasnovski/mini.pairs")
        -- Plug("echasnovski/mini.surround")
        -- Plug("tpope/vim-surround")
        -- Plug("tpope/vim-repeat")

        -- User Interface
        -- ------------------------------------------------------------------ --

        Plug("nvim-lualine/lualine.nvim")
        Plug("lukas-reineke/indent-blankline.nvim")
        Plug("beauwilliams/focus.nvim")
        Plug("nvim-telescope/telescope.nvim", {["tag"] = "0.1.1"}) 
        -- Plug("nvim-tree/nvim-tree.lua") -- Pretty bad for startup time, possibly perf.

        -- Themes
        -- ------------------------------------------------------------------ --

        Plug("rebelot/kanagawa.nvim")
        -- Plug("dracula/vim", { as = "dracula" })
        -- Plug("mvpopuk/inspired-github.vim")
        -- Plug("tomasiser/vim-code-dark")

        -- Language Servers & Completion
        -- ------------------------------------------------------------------ --

        Plug("neovim/nvim-lspconfig")
        Plug("williamboman/mason.nvim", { on = "Mason" })
        Plug("williamboman/mason-lspconfig.nvim")
        Plug("github/copilot.vim") -- DEPS: Node.js >= 16
        Plug("neoclide/coc.nvim", { branch = "release" }) -- DEPS: Node.js >= 14.14
        Plug("nvim-treesitter/nvim-treesitter", { ["do"] = "TSUpdate" })
        Plug("nvim-treesitter/playground")

        -- Language Support
        -- ------------------------------------------------------------------ --

        Plug("DanielGavin/ols", { ["for"] = "odin", ft = "odin"}) -- { ft = "odin" }
        -- Plug("DanielGavin/odin.vim", { ft = "odin" }) -- { ft = "odin" }
        Plug("ap29600/tree-sitter-odin", { ft = "odin" })
        -- Plug("simrat39/rust-tools.nvim", { ft = "rs" })

        -- Dependencies
        -- ------------------------------------------------------------------ --

        Plug("nvim-lua/plenary.nvim")
        Plug("nvim-lua/popup.nvim")

        -- Todos
        -- ------------------------------------------------------------------ --

        -- Plug("junegunn/fzf", { ["do"] = ":fzf#install()" })
        -- Plug("junegunn/fzf.vim")
        -- Plug("spywhere/tmux.nvim")

    vim.call("plug#end")

    -- ---------------------------------------------------------------------- --
    -- SETUP
    -- ---------------------------------------------------------------------- --

    -- focus.nvim
    -- ---------------------------------------------------------------------- --

    require("focus").setup({
        cursorline = false,
        signcolumn = false,
    })

    -- mini.align
    -- ---------------------------------------------------------------------- --

    require("mini.align").setup({}) -- TODO Add custom alignment rules.

    -- mini.pairs
    -- ---------------------------------------------------------------------- --

    require("mini.pairs").setup({})

    -- Impatient
    -- ---------------------------------------------------------------------- --

    require("impatient")

    -- filetype.nvim
    -- ---------------------------------------------------------------------- --

    -- TODO Document this.
    -- require("filetype").setup({
    --     overrides = {
    --         extensions = {
    --             odin = "odin",
    --             rs = "rust",
    --             lua = "lua",
    --         }
    --     }
    -- })


    -- lualine.nvim
    -- ---------------------------------------------------------------------- --

    -- Re-render the statusline and window bar every second.
    -- scripts.rerender_lualine()

    -- Return the currently active and inactive buffer numbers.
    -- scripts.get_inactive_buffer_numbers()
    -- scripts.get_active_buffer_number()

    -- local mode_section = {"mode", fmt = function(str) return str:sub(1,1) end}
    -- local filename_section = {"filename", file_status = true, newfile_status = true, path = 1, shorting_target = 10, symbols = {modified = "MO", readonly = "RO", unnamed = "UN", newfile = "NF"}}
    -- local windows_section = {"windows", mode = 1}

    require("lualine").setup {
        options = {
            always_divide_middle  = true,
            component_separators  = { left = "", right = "" },
            section_separators    = { left = "", right = "" },
            globalstatus          = false,
            icons_enabled         = false,
            theme                 = "kanagawa",
            -- theme              = "codedark",
            extensions            = {"nvim-tree"},
            -- disabled_filetypes = { "NvimTree", "netrw" },
        }, 
        sections = {
            lualine_a = {{'mode', show_modified_status = true, mode = 2},},
            lualine_b = {{'diagnostics'}},
            lualine_c = {{'filename', file_status = true, newfile_status = true, path = 1, shorting_target = 10, symbols = {modified = 'MO', readonly = 'RO', unnamed = 'UN', newfile = 'NF'}}},
            -- lualine_a = {{'mode', fmt = function(str) return str:sub(1,1) end}}, -- Display the mode as a single character.
            -- lualine_b = {'diff', 'diagnostics'},
            lualine_x = {},
            -- lualine_x = {{'buffers', mode = 1, show_modified_status = false, max_length = 3, padding = {left = 1, right = 0} },},
            lualine_y = {},
            -- lualine_y = {{"os.date('%I:%M:%S %p')"}}, -- Doesn't update consistently.
            lualine_z = {{'location'}},
            -- lualine_x = {{active_buffer_number, color = {fg = '#7E9CD8'}}, {inactive_buffer_numbers, color = {fg = '#717C7C'}, padding = {left = 0, right = 1}}},
            -- lualine_y = {{'progress'}},
            -- lualine_y = {{'fileformat', symbols = {unix = 'UNIX', dos = 'DOS', mac = 'Mac', odin = 'ODIN', lua = 'LUA'}}, 'filetype'},
        },  
    }

    -- Turn off lualine inside nvim-tree
    -- vim.cmd [[ au BufEnter,BufWinEnter,WinEnter,CmdwinEnter * if bufname("%") == "NvimTree_1" | set bufname("%") == "" | endif ]]

    -- auto-save
    -- ---------------------------------------------------------------------- --

    require("auto-save").setup({
        enabled = true,
        trigger_events = {"TextChanged"},
        execution_message = {
            message = function() return ("Auto-Saved at "..vim.fn.strftime("%H:%M:%S")) end,
            dim = 0.55,
        },
        write_all_buffers = false,
    })

    -- comment.nvim
    -- ---------------------------------------------------------------------- --

    require("Comment").setup({
        padding = true,
        sticky = true,
        mappings = { basic = true },
    })
    local ft = require("Comment.ft")
    ft.odin = {"//%s", "/*%s*/"}

    -- leap.nvim
    -- ---------------------------------------------------------------------- --

    require("leap").add_default_mappings()

    -- Indent Blankline
    -- ---------------------------------------------------------------------- --

    require("indent_blankline").setup {
        char = "┃",
        char_blankline = "┋",
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

    -- telescope 
    -- ---------------------------------------------------------------------- --

    local telescope_height = scripts.Golden("height")
    local telescope_width = scripts.Golden("width")

    local telescope = require("telescope").setup({
        defaults = {
            layout_strategy = "bottom_pane",
            borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
            results_title = false,
            layout_config = {
                prompt_position = "bottom",
            },
        },
    })

    -- nvim-treesitter
    -- ---------------------------------------------------------------------- --

    require("nvim-treesitter.configs").setup {
        ensure_installed = {'c', 'lua', 'python', 'rust', 'help', 'cmake', 'odin'},
        sync_install = false,
        auto_install = false,
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false, -- Slow.
        },
        -- text_objects = { enable = true },
        indent = {
            enable = false -- Experimental and broke indentation in Odin.
        },
        -- Neovim includes a built-in playground in >0.9.0
        playground = {
            enable = true,
            disable = {},
            updatetime = 25,
            persist_queries = true,
            keybindings = {
                toggle_query_editor = "o",
                toggle_hl_groups = "i",
                toggle_injected_languages = "t",
                toggle_anonymous_nodes = "a",
                toggle_language_display = "I",
                focus_language = "f",
                unfocus_language = "F",
                update = "R",
                goto_node = "<cr>",
                show_help = "?",
            },
        },
        -- query_linter = {
        --     enable = true,
        --     use_virtual_text = true,
        --     lint_events = {"BufWrite", "CursorHold"}
        -- },
    }

    -- mason.nvim
    -- ---------------------------------------------------------------------- --

    require("mason").setup()
    require("mason-lspconfig").setup()

    -- rust-tools
    -- ---------------------------------------------------------------------- --

    -- require("rust-tools").setup({
    --     server = {
    --         on_attach = function(_, bufnr)
    --             -- Hover actions
    --             vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
    --             -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-space>", rt.hover_actions.hover_actions, {buffer = bufnr})
    --             -- Code action groups
    --             vim.keymap.set("n", "<leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
    --         end,
    --     },
    -- })

    -- ols
    -- ---------------------------------------------------------------------- --

    if not require("lspconfig.configs").ols then
        require("lspconfig.configs").ols = {
            default_config = {
                cmd = { "ols" },
                filetypes = { "odin" },
                root_dir = require("lspconfig.util").root_pattern("ols.json", ".git"),
                single_file_support = true,
                on_attach = function(client, bufnr)
                    -- vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.MiniCompletion.completefunc_lsp") 
                    -- vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc") 
                end,
                settings = {},
            }
        }
    end
    require("lspconfig.configs").ols.setup{}

    -- pyright
    -- ---------------------------------------------------------------------- --

    -- Installed using npm.
    -- require("lspconfig").pyright.setup{}

    -- tree-sitter-odin
    -- ---------------------------------------------------------------------- --

    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    parser_config.odin = {
        install_info = {
            -- Files in the queries subdirectory of this plugin (C:\Users\Christopher\.config\nvim\plugs\tree-sitter-odin\queries\) are symlinked to Neovim's runtime directory: `~\scoop\apps\neovim\current\share\nvim\runtime\queries\odin`
            url = "C:/Users/Christopher/.config/nvim/plugs/tree-sitter-odin",
            files = { "src/parser.c" },
        },
    }

    -- kanagawa.nvim
    -- ---------------------------------------------------------------------- --

    -- local kanagawa = require("kanagawa.colors").setup()
    -- local overrides = { WinSeparator = { fg = kanagawa.bg_dark, bg = NONE }, }

    require("kanagawa").setup({
        -- colors = kanagawa,
        -- overrides = overrides,
        theme = "default", -- Load "default" theme or the experimental "light" theme
        undercurl = true,
        commentStyle = { italic = true },
        functionStyle = { bold = true },
        keywordStyle = { italic = false },
        statementStyle = { bold = true },
        typeStyle = { bold = true },
        variablebuiltinStyle = { italic = true },
        specialReturn = true, -- Special highlight for the return keyword.
        specialException = true, -- Special highlight for exception handling keywords.
        transparent = false , -- Do not set background color.
        terminalColors = true, -- Define vim.g.terminal_color_{0,17}.
        globalStatus = true,
        dimInactive = false, 
    })

    vim.cmd("colorscheme kanagawa")

    -- Vim Code Dark
    -- ---------------------------------------------------------------------- --

    -- vim.cmd("colorscheme codedark")

    -- ---------------------------------------------------------------------- --
    -- Todos
    -- ---------------------------------------------------------------------- --

    -- Nvim Tree 
    -- ---------------------------------------------------------------------- --

    -- TODO: Hard to keep track of buffers; flashing statusline is annoying.

    -- scripts.vsplit_preview()
    -- scripts.edit_or_open()
    -- scripts.collapse_all()

    -- TODO: Fix padding around buffers.

    -- require("nvim-tree").setup({
    --     sort_by = "type",
    --     -- sort_by = function(nodes)
    --     --     table.sort(nodes, natural_cmp)
    --     -- end,
    --     view = {
    --         cursorline = false,
    --         signcolumn = "no",
    --         mappings = {
    --             custom_only = false,
    --             list = {
    --                 { key = "l", action = "edit", action_cb = edit_or_open },
    --                 { key = "L", action = "vsplit_preview", action_cb = vsplit_preview },
    --                 { key = "h", action = "close_node" },
    --                 { key = "H", action = "collapse_all", action_cb = collapse_all }
    --             }
    --         },
    --     },
    --     actions = {
    --         open_file = {
    --             quit_on_open = false
    --         },
    --         file_popup = {
    --             open_win_config = {
    --                 col = 1,
    --                 row = 1,
    --                 relative = "cursor",
    --                 border = "none",
    --                 style = "minimal",
    --             },
    --         },
    --     },
    --     renderer = {
    --         highlight_opened_files = "all",
    --         highlight_modified = "all",
    --         icons = {
    --             modified_placement = "before",
    --             padding = "",
    --             show = {
    --                 file = true,
    --                 folder = false,
    --                 folder_arrow = true,
    --                 git = false,
    --                 modified = false,
    --             },
    --             glyphs = {
    --                 default = "",
    --                 symlink = "◀",
    --                 bookmark = "@",
    --                 modified = "",
    --                 folder = {
    --                     arrow_closed = "▶",
    --                     arrow_open = "▼",
    --                     default = "",
    --                     open = "●",
    --                     empty = "▷",
    --                     empty_open = "▽",
    --                     symlink = "◀",
    --                     symlink_open = "◁",
    --                 },
    --             },
    --         },
    --     },
    -- })

    -- Close tree if it's the last open window (naive solution)
    -- vim.api.nvim_create_autocmd("BufEnter", {
    --     group = vim.api.nvim_create_augroup("NvimTreeClose", {clear = true}),
    --     pattern = "NvimTree_*",
    --     callback = function()
    --         local layout = vim.api.nvim_call_function("winlayout", {})
    --         if layout[1] == "leaf" and vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(layout[2]), "filetype") == "NvimTree" and layout[3] == nil then vim.cmd("confirm quit") end
    --     end
    -- })

end

