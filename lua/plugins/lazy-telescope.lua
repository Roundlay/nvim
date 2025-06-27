-- telescope.nvim
return {
    'nvim-telescope/telescope.nvim',
    enabled = true,
    version = false,
    condition = function() if (vim.g.vscode) then return false end end,
    lazy = true,
    event = "CmdlineEnter",
    keys = {
        { ";f", "<cmd>Telescope find_files<CR>", desc = "Find file..." },
        { ";g", "<cmd>Telescope live_grep<CR>", desc = "GREP..." },
        { ";b", "<cmd>Telescope buffers<CR>", desc = "Find buffer..." },
        { ";;", "<cmd>Telescope help_tags<CR>", desc = "Display help tags..." },
        { ";c", "<cmd>Telescope commands<CR>", desc = "Display command history..." },
    },
    dependencies = {
        { "nvim-lua/plenary.nvim", module = "telescope" },
    },
    opts = {
        defaults = {
            layout_strategy = "horizontal",
            layout_config = {
                width = function(_, cols, _)
                    if cols > 200 then
                        return 170  -- Fixed width for large windows
                    else
                        return math.floor(cols * 0.87)  -- Dynamic width for smaller windows
                    end
                end,
                height = function(_, _, max_lines)
                    return math.floor(max_lines * 0.8)   -- 80% of the window height
                end,
                prompt_position = "bottom",
                preview_width = 0.5,                     -- 50% split between preview and results
                preview_cutoff = 120,                    -- Disable preview if width is less than 120
            },
            previewer = true,
            prompt_title = "",
            results_title = "",
            preview_title = "",
            dynamic_preview_title = true,
            selection_caret = "",
            entry_prefix = "",
            multi_icon = "",
            color_devicons = false,
            border = true,
            borderchars = { "━", "┃", "━", "┃", "┏", "┓", "┛", "┗" },
            preview = { msg_bg_fillchar = '' },
        },
    },
    config = function(_, opts)
		local telescope_ok, telescope = pcall(require, "telescope")
		if not telescope_ok then
            vim.notify(vim.inspect(telescope), vim.log.levels.ERROR)
			return
		end
        telescope.setup(opts)
    end,
}
