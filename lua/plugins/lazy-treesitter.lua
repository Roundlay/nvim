return {
    "nvim-treesitter/nvim-treesitter",
    enabled = true,
    version = false,
    build = ":TSUpdateSync",
    lazy = true,
    opts = {
        sync_install = false,
        auto_install = true,
    },
    config = function(_, opts)
        local nvim_treesitter_ok, nvim_treesitter = pcall(require, "nvim-treesitter.configs")
        if not nvim_treesitter_ok then
            print("Error loading `nvim_treesitter`.")
            return
        end
        nvim_treesitter.setup(opts)
    end
}
