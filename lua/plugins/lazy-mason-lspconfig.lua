-- mason-lspconfig.nvim

-- Notes:

-- Incomming dependencies: neovim/nvim-lspconfig
-- Outgoing dependencies: mason.nvim
-- It's important that this be called after `mason.nvim` and before `lspconfig`.
-- Lazy's dependencies are a little counterintuitive. The `dependencies` field
-- defines what plugins must be loaded before the plugin listing the dependency.
-- Load order: mason.nvim -> mason-lspconfig.nvim -> lspconfig
-- Dependency flow: lspconfig -> mason.nvim <- mason-lspconfig.nvim

return {
    "williamboman/mason-lspconfig.nvim",
    lazy = true,
    dependencies = {
        -- Depedencies to be loaded before nvim-lspconfig.
        "williamboman/mason.nvim",
    },
    config = function(_, opts)
        local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
        if not mason_lspconfig_ok then
            vim.notify(vim.inspect(mason_lspconfig), vim.log.levels.ERROR)
            return
        end
        opts = vim.tbl_deep_extend("force", {
            -- NOTE: Mason does not package `sourcekit` (Swift's SourceKit-LSP). It must be
            -- installed via Xcode/Swift toolchain separately and is configured directly in
            -- `lazy-lspconfig.lua`. Keep it out of `ensure_installed` to avoid startup errors.
            ensure_installed = {
                "lua_ls",
                "clangd",
                "pyright",
                "ols",
                "yamlls",
                "jsonls",
                "html",
                "cssls",
                "vimls",
                "marksman",
            },
            automatic_installation = false,
        }, opts or {})
        mason_lspconfig.setup(opts)
    end
}
