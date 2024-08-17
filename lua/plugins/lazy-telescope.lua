-- telescope.nvim
return {
    'nvim-telescope/telescope.nvim',
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
            -- layout_strategy = "bottom_pane",
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
            -- layout_config = {
            --     width = 1.00,
            --     height = 0.50,
            --     prompt_position = "bottom",
            -- },
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
