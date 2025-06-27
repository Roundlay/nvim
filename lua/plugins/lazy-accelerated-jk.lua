-- accelerated-jk.nvim

return {
    "rainbowhxch/accelerated-jk.nvim",
    enabled = false,
    lazy = true,
    keys = {
        {"j", "<Plug>(accelerated_jk_j)", desc = "Accelerated <j>"},
        {"k", "<Plug>(accelerated_jk_k)", desc = "Accelerated <k>"},
    },
    opts = {
        -- time_driven: The default one. With this mode, if the interval of key-repeat
        -- takes more than `acceleration_limit` ms, the step is reset. If you want to
        mode = "time_driven",
        enable_deceleration = true,
        acceleration_limit = 150,
        -- Each value in the acceleration table represents the number of
        -- <j> or <k> inputs required to increase the acceleration multiple by the
        -- index of the value in the table. E.g. for {5, 10, 20} the acceleration
        -- multiples are {1x, 2x, 3x}, and so on. The accceleration multiple will
        -- be 1x until the equivalent of 5*<j> inputs have been received, 2x when
        -- the equivalent of 5-10 <j> inputs have been received, and 3x when the
        -- equivalent of 10-20 <j> inputs have been received.
        acceleration_table = {20, 40, 80, 160},
        -- Each of the values in the deceleration table represents: elapsed time
        -- after last j/k input, and the count to decelerate steps. The default values seem to be {{150, 9999}}.
        deceleration_table = {{5, 50}},
    },
    config = function(_, opts)
		local acceleratedjk_ok, accelerated_jk = pcall(require, "accelerated-jk")
		if not acceleratedjk_ok then
            vim.notify(vim.inspect(accelerated_jk), vim.log.levels.ERROR)
			return
		end
        accelerated_jk.setup(opts)
    end,
}
