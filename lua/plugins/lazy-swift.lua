return {
    "devswiftzone/swift.nvim",
    ft = "swift",
    opts = {
        features = {
            lsp = {
                auto_setup = false,
                on_attach = function(client, bufnr)
                    -- Your custom keybindings
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
                    -- vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr })
                end,
            },
        },
    },  -- Uses default configuration
    config = function(_, opts)
        opts.features = opts.features or {}
        opts.features.lsp = vim.tbl_deep_extend("force", { auto_setup = false }, opts.features.lsp or {})

        local swift_ok, swift = pcall(require, "swift")
        if not swift_ok then
            vim.notify(vim.inspect(swift), vim.log.levels.ERROR)
            return
        end

        swift.setup(opts)

        if not vim.lsp or not vim.lsp.config then
            vim.notify("vim.lsp.config API not available (requires Neovim 0.11+).", vim.log.levels.ERROR)
            return
        end

        local swift_config = require("swift.config")
        if not swift_config.is_feature_enabled("lsp") then
            return
        end

        local swift_lsp_ok, swift_lsp = pcall(require, "swift.features.lsp")
        if not swift_lsp_ok then
            vim.notify("swift.nvim LSP feature failed to load: " .. tostring(swift_lsp), vim.log.levels.ERROR)
            return
        end

        local lsp_feature = swift_config.get_feature("lsp") or {}
        local cmd = lsp_feature.cmd

        if not cmd or (type(cmd) == "table" and vim.tbl_isempty(cmd)) then
            local sourcekit_path = swift_lsp.find_sourcekit_lsp()
            if not sourcekit_path then
                vim.notify("sourcekit-lsp not found. Install a Swift toolchain or set features.lsp.cmd.", vim.log.levels.WARN, { title = "swift.nvim" })
                return
            end
            cmd = { sourcekit_path }
        elseif type(cmd) == "string" then
            cmd = { cmd }
        end

        local filetypes = lsp_feature.filetypes or { "swift" }
        local base_config = vim.lsp.config["sourcekit"]
        local capabilities = swift_lsp.get_capabilities()

        if base_config and base_config.capabilities then
            local base_capabilities = vim.deepcopy(base_config.capabilities)
            if capabilities then
                capabilities = vim.tbl_deep_extend("force", base_capabilities, capabilities)
            else
                capabilities = base_capabilities
            end
        end

        local root_dir = nil
        local root_dir_provider = swift_lsp.get_root_dir()

        if type(root_dir_provider) == "function" then
            local info = debug.getinfo(root_dir_provider, "u")
            if info and info.nparams and info.nparams >= 2 then
                root_dir = root_dir_provider
            else
                root_dir = function(bufnr, on_dir)
                    local target = bufnr
                    if type(bufnr) == "number" then
                        target = vim.api.nvim_buf_get_name(bufnr)
                    end
                    local resolved = root_dir_provider(target)
                    if on_dir then
                        on_dir(resolved)
                    else
                        return resolved
                    end
                end
            end
        elseif base_config and base_config.root_dir then
            root_dir = base_config.root_dir
        end

        local overrides = {
            cmd = cmd,
            filetypes = filetypes,
            root_dir = root_dir,
            settings = lsp_feature.settings or {},
            capabilities = capabilities,
            on_attach = swift_lsp.default_on_attach,
        }

        local merged = overrides
        if base_config then
            merged = vim.tbl_deep_extend("force", {}, base_config, overrides)
        end

        vim.lsp.config("sourcekit", merged)
        vim.lsp.enable("sourcekit")
    end,
}
