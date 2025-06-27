-- clangd_extensions.nvim

return {
    "p00f/clangd_extensions.nvim",
    enabled = false;
    lazy = true,
    version = false,

    dependencies = {
        "neovim/nvim-lspconfig",
    },

    keys = {
        { "<leader>ih", "<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })<cr>", desc = "Toggle Inlay Hints" },
    },

    opts = {
        server = {
            -- Defer to lspconfig's clangd setup; only override on_attach
            on_attach = function(client, bufnr)
                if client.server_capabilities.inlayHintProvider then
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                end
            end,
        },
        extensions = {
            inlay_hints = {
                inline = false, -- Use end-of-line hints (set to true for inline if Neovim supports it)
                only_current_line = false, -- Show hints for all lines
                show_parameter_hints = true, -- Show parameter names in function calls
                parameter_hints_prefix = "", -- No prefix for parameter hints
                show_variable_name = true, -- Show variable names for deduced types
                other_hints_prefix = "=> ", -- Prefix for return type hints (e.g., => int)
                max_len = 25, -- Max length for hint text
                right_align = false, -- Align hints to the right
            },
        },
    },

    config = function(_, opts)
        local clangd_ext_ok, clangd_ext = pcall(require, "clangd_extensions")
        if not clangd_ext_ok then
            vim.notify(vim.inspect(clangd_ext), vim.log.levels.ERROR)
            return
        end
        clangd_ext.setup(opts)
    end,
}
