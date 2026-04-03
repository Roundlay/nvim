if vim.g.loaded_wrappin_plugin == 1 then
    return
end

vim.g.loaded_wrappin_plugin = 1

vim.api.nvim_create_user_command("Wrappin", function(command_opts)
    require("wrappin").command(command_opts)
end, {
    desc = "Reflow or restore wrapped text in a range",
    nargs = "?",
    range = true,
})

vim.keymap.set("n", "<Plug>(Wrappin)", function()
    require("wrappin").wrap_current_line()
end, {
    desc = "Wrap current line with wrappin",
    silent = true,
})

vim.keymap.set("x", "<Plug>(Wrappin)", function()
    require("wrappin").wrap_visual()
end, {
    desc = "Wrap visual selection with wrappin",
    silent = true,
})
