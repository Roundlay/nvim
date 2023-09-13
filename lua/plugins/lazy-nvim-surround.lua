-- nvim-surround

return {
    "kylechui/nvim-surround",
    enabled = true,
    version = "*",
    lazy = true,
    event = "VeryLazy",
    opts = {
    },
    config = function(_, opts)
        local nvim_surround_ok, nvim_surround = pcall(require, "nvim-surround")
        if not nvim_surround_ok then
            print("Error loading 'nvim-surround'.")
            return
        end
        nvim_surround.setup(opts)
    end
}
