-- mason.nvim

return {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = "Mason",
    opts = {
        ui = {
            border = "none",
        },
    },
}
