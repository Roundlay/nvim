-- copilot.lua
-- https://github.com/zbirenbaum/copilot.lua

return {
    "zbirenbaum/copilot.lua",
    enabled = true,
    lazy = true,
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter",
    config = function()
        require("copilot").setup({
            suggestion = { enabled = true },
            panel = { enabled = true },
        })
    end
}
