-- copilot.lua
-- https://github.com/zbirenbaum/copilot.lua
-- ------------------------------------------------------------------------- --

return {
    "zbirenbaum/copilot.lua",
    enabled = true,
    lazy = true,
    event = "InsertEnter",
    config = function()
        require("copilot").setup({})
    end,
}
