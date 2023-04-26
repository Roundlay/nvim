return {
    "L3MON4D3/LuaSnip",
    name = "LuaSnip",
    enabled = true,
    lazy = true,
    -- event = "VimEnter",
    config = function()
        local luasnip_ok, luasnip = pcall(require, "luasnip")
        if not luasnip_ok then
          return
        end
        luasnip.config.set_config {
            history = true, -- Keep the last snipped around.
            updateevents = "TextChanged,TextChanged", -- Update dynamic snippets as you type
            enable_autosnippets = true,
        }
    end,
}
