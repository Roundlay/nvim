-- nvim-scrollbar

return {
    "petertriho/nvim-scrollbar",
    enabled = false,
    lazy = true,
    event = "BufReadPre",
    opts = {
        show = true,
        hide_if_all_visible = false,
        show_in_active_only = true,
        throttle_ms = 1,
        excluded_buftypes = {
            "acwrite", -- E.g. oil.nvim (?)
            "nofile", -- E.g. the Lazy interface
        },
        exclude_filetypes = {
            "cmp_docs",
            "cmp_menu",
            "TelescopePrompt",
        },
        handle = {
            text = " ",
            blend = 33,
            color = nil,
            color_nr = nil,
            highlight = "CursorColumn",
            hide_if_all_visible = false,
        },
        handlers = {
            cursor = true,
            diagnostic = true,
            handle = true,
            search = false,
        },
        marks = {
            Cursor = {
                -- text = "",
                -- text = "◆",
                text = "●",
                priority = 0,
                gui = nil,
                color = "#1F1F28",
                cterm = nil,
                color_nr = nil, -- cterm
                highlight = "Normal",
            },
        },
    },
    config = function(_, opts)
		local scrollbar_ok, scrollbar = pcall(require, "scrollbar")
		if not scrollbar_ok then
            vim.notify(vim.inspect(scrollbar), vim.log.levels.ERROR)
			return
		end
        scrollbar.setup(opts)
    end
}
