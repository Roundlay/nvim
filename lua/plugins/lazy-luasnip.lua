-- LuaSnip

return {
    "L3MON4D3/LuaSnip",
    -- name = "LuaSnip",
    version = "2.*",
    enabled = false,
    lazy = true,
    -- event = "VimEnter",
    config = function()
        local luasnip_ok, luasnip = pcall(require, "luasnip")
        if not luasnip_ok then
            vim.notify(vim.inspect(luasnip), vim.log.levels.ERROR)
            return
        end
        luasnip.config.set_config {
            history = true, -- Keep the last snipped around.
            updateevents = "TextChanged,TextChanged", -- Update dynamic snippets as you type
            enable_autosnippets = true,
        }
    end,
}
