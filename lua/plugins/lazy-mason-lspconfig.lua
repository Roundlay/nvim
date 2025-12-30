-- mason-lspconfig.nvim

return {
    "williamboman/mason-lspconfig.nvim",
    lazy = true,
    enabled = true,
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
        -- lspconfig server names (mason-lspconfig translates to Mason package names)
        local server_names = {
            "clangd",
            "cssls",
            "html",
            "jsonls",
            "lua_ls",
            "marksman",
            "ols",
            "pyright",
            "vimls",
            "yamlls",
        }
        opts = vim.tbl_deep_extend("force", {
            -- NOTE: Mason does not package `sourcekit` (Swift's SourceKit-LSP). It must be
            -- installed via Xcode/Swift toolchain separately and is configured directly in
            -- `lazy-lspconfig.lua`. Keep it out of `ensure_installed` to avoid startup errors.
            ensure_installed = vim.deepcopy(server_names),
            automatic_installation = false,
        }, opts or {})
        mason_lspconfig.setup(opts)
    end
}
