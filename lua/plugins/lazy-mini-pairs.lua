-- mini.pairs

return {
	"echasnovski/mini.pairs",
    -- name = "mini-pairs",
    version = false,
    enabled = false,
    lazy = true,
    event = "InsertEnter",
	config = function()
		require("mini.pairs").setup({})
	end,
}
