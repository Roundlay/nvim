return {
    "L3MON4D3/LuaSnip",
    name = "LuaSnip",
    enabled = true,
    event = "VimEnter",
    config = function()
        local luasnip = require("luasnip")
        luasnip.config.set_config {
            history = true, -- Keep the last snipped around.
            updateevents = "TextChanged,TextChanged", -- Update dynamic snippets as you type
            enable_autosnippets = true,
        }
    end
}
