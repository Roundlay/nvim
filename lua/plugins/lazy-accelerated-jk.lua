return {
    "rainbowhxch/accelerated-jk.nvim",
    name = "accelerated-jk",
    enabled = false,
    lazy = true,
    event = {"BufReadPost", "InsertEnter"},
    keys = {
        {"j", "<Plug>(accelerated_jk_j)", desc = "Accelerated j"},
        {"k", "<Plug>(accelerated_jk_k)", desc = "Accelerated k"},
    },
    opts = {
        mode = "time_driven",
        enable_deceleration = true,
        acceleration_table = {12,18,24,30},
        deceleration_table = {{50, 200}},
    },
    config = function(_, opts)
        require("accelerated-jk").setup(opts)
    end,
}
