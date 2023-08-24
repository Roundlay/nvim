-- nvim-scrollbar

return {
    "petertriho/nvim-scrollbar",
    -- name = "scrollbar",
    enabled = true,
    lazy = true,
    event = "BufReadPre",
    opts = {
        show = true,
        hide_if_all_visible = true,
        show_in_active_only = true,
        throttle_ms = 1,
        exclude_filetypes = {
            "cmp_docs",
            "cmp_menu",
            "TelescopePrompt",
        },
        handle = {
            text = " ",
            blend = 50, -- Integer between 0 and 100. 0 for fully opaque and 100 to full transparent. Defaults to 30.
            color = nil,
            color_nr = nil, -- cterm
            highlight = "CursorColumn",
            hide_if_all_visible = true, -- Hides handle if all lines are visible
        },
        marks = {
            Cursor = {
                -- text = "◆",
                text = "",
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
            print("Error loading 'nvim-scrollbar'.")
			return
		end
        scrollbar.setup(opts)
    end,
}
