-- mini.pairs

return {
	"echasnovski/mini.pairs",
    name = "mini-pairs",
    version = false,
    enabled = true,
    lazy = true,
    event = "InsertEnter",
	config = function()
		require("mini.pairs").setup()
	end,
}
