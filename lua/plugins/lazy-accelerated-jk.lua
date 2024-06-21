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
        acceleration_table = {12, 24, 48},
        deceleration_table = {{50, 200}},
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
