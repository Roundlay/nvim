return {
    "echasnovski/mini.align",
    name = "Mini-Align",
    enabled = true,
    lazy = false, -- We may want to align text immediately upon launching Neovim.
    config = function()
        local mini_align_ok, mini_align = pcall(require, "mini.align")
        if not mini_align_ok then
            print("Issue loading 'mini.align'.")
            return
        else
            mini_align.setup() -- TODO Add custom alignment rules.
        end
    end
}
