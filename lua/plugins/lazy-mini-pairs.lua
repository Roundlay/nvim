-- mini.pairs

return {
	"echasnovski/mini.pairs",
    name = "Mini-Pairs",
    version = false,
    enabled = true,
    lazy = true,
    event = "InsertEnter",
	config = function()
		require("mini.pairs").setup()
	end,
}
