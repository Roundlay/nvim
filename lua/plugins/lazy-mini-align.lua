-- mini.align

return {
    "echasnovski/mini.align",
    -- name = "mini-align",
    lazy = true, -- We may want to align text immediately upon launching Neovim.
    -- event = {"BufReadPost", "InsertCharPre"},
    keys = {
        {"ga", mode = { "v" }, desc = "Align."},
    },
    opts = {
        mappings = {
            start_with_preview = "ga",
        },
        -- Tweak 'j' modifier to cycle through available "justify_side" options.
        modifiers = {
          j = function(_, opts)
            local next_option = ({
              left = 'center', center = 'right', right = 'none', none = 'left',
            })[opts.justify_side]
            opts.justify_side = next_option or 'left'
          end,
        },
    },
}
