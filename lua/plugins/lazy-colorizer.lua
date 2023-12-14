-- colorizer.lua
-- https://github.com/norcalli/nvim-colorizer.lua

-- A high-performance color highlighter for Neovim which has no dependencies.
-- This adds background color highlighting to color codes. E.g. #FFFFFF."

-- The plugin relies on AutoCmd to attach and run, so you might need to call
-- `ColorizerAttachToBuffer` to attach the plugin to the current buffer if
-- the file you're editing doesn't have a filetype, or if you're using a plugin
-- to manage filetypes, like `filetype.nvim`.

return {
    "norcalli/nvim-colorizer.lua",
    enabled = false,
    lazy = true,
    event = {
        "BufReadPost",
    },
    opts = {
        RGB = true,
        rgb_fn = true,
        hsl_fn = true,
        css = true,
        css_fn = true,
        mode = "background",
    },
    config = function(_, opts)
		local colorizer_ok, colorizer = pcall(require, "colorizer")
		if not colorizer_ok then
            vim.notify(vim.inspect(colorizer), vim.log.levels.ERROR)
			return
		end
        colorizer.setup(opts)
    end,
}
