-- plugins.lua
-- -------------------------------------------------------------------------- --

-- local scripts = require("scripts")
local Plug = vim.fn["plug#"]

-- -------------------------------------------------------------------------- --
-- Visual Studio Code
-- -------------------------------------------------------------------------- --

if (vim.g.vscode) then

    vim.call("plug#begin", "~/.config/nvim/plugs")

        Plug("justinmk/vim-sneak")
        Plug("unblevable/quick-scope")

    vim.call("plug#end")

    return

end

-- -------------------------------------------------------------------------- --
-- Neovim
-- -------------------------------------------------------------------------- --

vim.call("plug#begin", "~/.config/nvim/plugs")

    -- Meta
    -- ---------------------------------------------------------------------- --

    Plug("lewis6991/impatient.nvim")
    Plug("Pocco81/auto-save.nvim")
    -- Plug("nathom/filetype.nvim")

    -- Editor
    -- ---------------------------------------------------------------------- --

    Plug("ggandor/leap.nvim")
    Plug("numToStr/Comment.nvim")
    Plug("unblevable/quick-scope")
    Plug("echasnovski/mini.align")
    Plug("echasnovski/mini.pairs")
    -- Plug("echasnovski/mini.surround")
    -- Plug("tpope/vim-surround")
    -- Plug("tpope/vim-repeat")

    -- User Interface
    -- ---------------------------------------------------------------------- --

    Plug("beauwilliams/focus.nvim")
    Plug("nvim-lualine/lualine.nvim")
    Plug("lukas-reineke/indent-blankline.nvim")
    Plug("nvim-telescope/telescope.nvim", {["tag"] = "0.1.1"}) -- DEPS: plenary
    -- Plug("nvim-tree/nvim-tree.lua") -- Pretty bad for startup time, possibly perf.

    -- Language Parsing
    -- ---------------------------------------------------------------------- --

    Plug("nvim-treesitter/nvim-treesitter", { ["do"] = "TSUpdate" })
    Plug("nvim-treesitter/playground")

    -- LSP Support
    -- ---------------------------------------------------------------------- --

    Plug("neovim/nvim-lspconfig")
    Plug("williamboman/mason.nvim", { on = "Mason", ["do"] = "MasonUpdate"})
    Plug("williamboman/mason-lspconfig.nvim")

    -- Completion
    -- ---------------------------------------------------------------------- --

    Plug("github/copilot.vim") -- DEPS: Node.js >= 16
    Plug("hrsh7th/nvim-cmp")
    Plug("hrsh7th/cmp-path")
    Plug("hrsh7th/cmp-nvim-lsp") -- A nvim-cmp source for Neovim's built-in LSP client. Allows for e.g. ols to pass completion candidates on to nvim-cmp.
    Plug("hrsh7th/cmp-nvim-lsp-signature-help") -- A nvim-cmp source for Neovim's built-in LSP client. Allows for e.g. ols to pass completion candidates on to nvim-cmp.
    Plug("L3MON4D3/LuaSnip")
    Plug("VonHeikemen/lsp-zero.nvim", { branch = "v2.x" })
    -- Plug("neoclide/coc.nvim", { branch = "release" }) -- DEPS: Node.js >= 14.14

    -- Language Servers
    -- ---------------------------------------------------------------------- --

    -- Plug("DanielGavin/ols", { ft = "odin"})
    -- Plug("DanielGavin/odin.vim", { ft = "odin" })
    Plug("ap29600/tree-sitter-odin", { ft = "odin" })
    -- Plug("simrat39/rust-tools.nvim", { ft = "rs" })

    -- Diagnostics
    -- ---------------------------------------------------------------------- --

    Plug("folke/trouble.nvim")

    -- Dependencies
    -- ---------------------------------------------------------------------- --

    Plug("nvim-lua/plenary.nvim")
    Plug("nvim-lua/popup.nvim")

    -- Themes
    -- ---------------------------------------------------------------------- --

    Plug("rebelot/kanagawa.nvim")
    -- Plug("dracula/vim", { as = "dracula" })
    -- Plug("mvpopuk/inspired-github.vim")
    -- Plug("tomasiser/vim-code-dark")

    -- Todos
    -- ---------------------------------------------------------------------- --

    -- Plug("junegunn/fzf", { ["do"] = ":fzf#install()" })
    -- Plug("junegunn/fzf.vim")
    -- Plug("spywhere/tmux.nvim")

vim.call("plug#end")

-- -------------------------------------------------------------------------- --
-- SETUP
-- -------------------------------------------------------------------------- --

-- folke/trouble.nvim
-- -------------------------------------------------------------------------- --

require("trouble").setup {
    position = "bottom",
    padding = true,
    icons = false,
    height = 10,
    fold_open = "v", -- icon used for open folds
    fold_closed = ">", -- icon used for closed folds
    indent_lines = true, -- add an indent guide below the fold icons
    signs = {
        -- icons / text used for a diagnostic
        error = "  ERROR",
        warning = "",
        hint = "",
        information = ""
    },
    use_diagnostic_signs = false -- enabling this will use the signs defined in your lsp client

}

-- focus.nvim
-- -------------------------------------------------------------------------- --

require("focus").setup({
    cursorline = false,
    signcolumn = false,
})

-- mini.align
-- -------------------------------------------------------------------------- --

local mini_align_ok, mini_align = pcall(require, "mini.align")
if not mini_align_ok then
    print("Issue loading 'mini.align'.")
    return
else
    mini_align.setup({}) -- TODO Add custom alignment rules.
end

-- mini.pairs
-- -------------------------------------------------------------------------- --

local mini_pairs_ok, mini_pairs = pcall(require, "mini.pairs")
if not mini_pairs_ok then
    print("Issue loading 'mini.pairs'.")
    return
else
    mini_pairs.setup({})
end

-- lewis6991/impatient.nvim
-- -------------------------------------------------------------------------- --

require("impatient")

-- filetype.nvim
-- -------------------------------------------------------------------------- --

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
-- -------------------------------------------------------------------------- --

-- Re-render the statusline and window bar every second.
-- scripts.rerender_lualine()

-- Return the currently active and inactive buffer numbers.
-- scripts.get_inactive_buffer_numbers()
-- scripts.get_active_buffer_number()

require("lualine").setup {
    options = {
        always_divide_middle  = true,
        component_separators  = { left = "", right = "" },
        section_separators    = { left = "", right = "" },
        globalstatus          = false,
        icons_enabled         = false,
        theme                 = "kanagawa",
        extensions            = {"nvim-tree"},
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

-- Pocco81/auto-save.nvim
-- -------------------------------------------------------------------------- --

local auto_save_ok, auto_save = pcall(require, "auto-save")

if not auto_save_ok then
    print("Issue loading 'Pocco81/auto-save.nvim'.")
else
    auto_save.setup({
        enabled = true,
        trigger_events = {"TextChanged"},
        execution_message = {
            message = function() return ("Auto-Saved at "..vim.fn.strftime("%H:%M:%S")) end,
            dim = 0.50,
        },
        write_all_buffers = false,
    })
end

-- numToStr/Comment.nvim
-- -------------------------------------------------------------------------- --

require("Comment").setup({
    padding = true,
    sticky = true,
    mappings = { basic = true },
})
local ft = require("Comment.ft")
ft.odin = {"//%s", "/*%s*/"}

-- ggandor/leap.nvim
-- -------------------------------------------------------------------------- --

require("leap").add_default_mappings()

-- lukas-reineke/indent-blankline.nvim
-- -------------------------------------------------------------------------- --

require("indent_blankline").setup {

    char = "┃",
    char_blankline = "┋",
    show_end_of_line = true,
    show_first_indent_level = true,
    show_trailing_blankline_indent = true,
    -- max_indent_increase = 1,
    strict_tabs = true,
    viewport_buffer = 50,
    filetype_exclude = {"txt", "help", "md", "yaml"},
    use_treesitter = false,
    use_treesitter_scope = true,

}

-- nvim-telescope/telescope.nvim
-- -------------------------------------------------------------------------- --

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
-- -------------------------------------------------------------------------- --

require("nvim-treesitter.configs").setup {
    ensure_installed = {'c', 'lua', 'python', 'rust', 'help', 'cmake'},
    sync_install = false,
    auto_install = false,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false, -- Slow.
    },
    -- text_objects = { enable = true },
    -- indent = {
    --     enable = false -- Experimental and broke indentation in Odin.
    -- },
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

-- tree-sitter-odin
-- -------------------------------------------------------------------------- --

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.odin = {
    install_info = {
        -- Files in the queries subdirectory of this plugin (C:\Users\Christopher\.config\nvim\plugs\tree-sitter-odin\queries\) are symlinked to Neovim's runtime directory: `~\scoop\apps\neovim\current\share\nvim\runtime\queries\odin`
        url = "C:/Users/Christopher/.config/nvim/plugs/tree-sitter-odin",
        files = { "src/parser.c" },
    },
}

-- luasnip
-- -------------------------------------------------------------------------- --

local ls = require("luasnip")
local types = require("luasnip.util.types")
ls.config.set_config {
    history = true, -- Keep the last snipped around.
    updateevents = "TextChanged,TextChangedI", -- Update dynamic snippets as you type
    enable_autosnippets = true,
}

-- -------------------------------------------------------------------------- --
-- LSP Setup
-- -------------------------------------------------------------------------- --

-- mason.nvim
-- -------------------------------------------------------------------------- --

require("mason").setup({
    ui = {
        border = "none",
    }
})
require("mason-lspconfig").setup({
    -- ensure_installed = {
    --     -- ...
    -- }
})

-- lsp-zero.nvim
-- -------------------------------------------------------------------------- --

local lspzero = require('lsp-zero').preset({
    float_border = "none", -- Remove borders to diagnostics windows.
    configure_diagnostics = true,
})


lspzero.on_attach(function(client, bufnr)
    lspzero.default_keymaps({buffer = bufnr})
end)

-- lspzero.ensure_installed({"",})

-- nvim-lspconfig
-- -------------------------------------------------------------------------- --

local lspconfig    = require("lspconfig")
local lsp_configs  = require("lspconfig.configs") -- This is where servers that aren't supported by lspconfig are stored.
local lsp_util     = require("lspconfig.util")

local lsp_defaults = lspconfig.util.default_config

-- nvim-cmp
-- -------------------------------------------------------------------------- --

local cmp = require("cmp")

-- local on_attach = function(_, bufnr)
--     vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
--     vim.api.nvim_buf_set_keymap(0, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', {noremap = true, silent = true}) -- Go-to-definition
-- end

cmp.setup({
    performance = { debounce = 0, throttle = 0, fetching_timeout = 0, },
    window = {
        completion    = { scrollbar = false, },
        documentation = { scrollbar = false, side_padding = 2, max_height = 80, },
    },
    view = {
        entries = "custom",
    },
    formatting = {
        format = function(entry, item)
            item.menu = ({
                buffer = "[Buffer]",
                nvim_lsp = "[LSP]",
            })[entry.source.name]
            if entry.source.source.client then
                item.menu = ("%s - %s"):format(item.menu, entry.source.source.client.name)
            end

            return item
        end
    },
    -- Only really relevant when luasnip is setup. Probably pretty powerful though.
    snippet = {
        expand = function(args) require("luasnip").lsp_expand(args.body) end,
    },
    sources = {
        { name = "luasnip", options = {}, },
        { name = "path", options = {}, },
        { name = "nvim_lsp", options = {}, },
        { name = "nvim_lsp_signature_help" },
    },
    mapping = {
        ["<CR>"] = cmp.mapping.confirm({select = false}),
        ["<C-Space>"] = cmp.mapping.complete(),
    },
})


-- luals
-- -------------------------------------------------------------------------- --

lspconfig.lua_ls.setup(lspzero.nvim_lua_ls())

-- ols
-- -------------------------------------------------------------------------- --

local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- This is the default schema for adding custom servers to nvim-lspconfig.

if not lsp_configs.ols then
    lsp_configs.ols = {
        default_config = {
            cmd = { "ols" },
            filetypes = { "odin" },
            root_dir = lsp_util.root_pattern("ols.json", ".git"),
            single_file_support = true,
            on_attach = function(client, bufnr)
                -- Stuff to do when the server attaches.
            end,
            settings = {},
        }
    }
end

lsp_configs.ols.setup{
    capabilities = capabilities,
}

-- Finish lsp-zero setup
lspzero.setup()

-- rust-tools
-- -------------------------------------------------------------------------- --

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

-- pyright
-- -------------------------------------------------------------------------- --

-- Installed using npm.
-- require("lspconfig").pyright.setup{}

-- kanagawa.nvim
-- -------------------------------------------------------------------------- --

-- local kanagawa = require("kanagawa.colors").setup()
-- local overrides = { WinSeparator = { fg = kanagawa.bg_dark, bg = NONE }, }
-- local colors = require("kanagawa.colors").setup()
-- local theme = colors.theme

require("kanagawa").setup({
    theme = "wave",
    undercurl = true,
    commentStyle = { italic = false },
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

-- vim.cmd("colorscheme kanagawa")

-- Vim Code Dark
-- -------------------------------------------------------------------------- --

-- vim.cmd("colorscheme codedark")


-- -------------------------------------------------------------------------- --
-- Graveyard
-- -------------------------------------------------------------------------- --

-- Nvim Tree 
-- -------------------------------------------------------------------------- --

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

