-- flash.nvim

return {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
        search = {
            multi_window = true,
            mode = "exact",
            exclude = {
              "cmp_menu",
              "flash_prompt",
            },
        },
        label = {
            uppercase = true,
            style = "overlay",
            after = true,
            rainbow = {
              enabled = false,
              -- number between 1 and 9
              shade = 5,
            },
        },
        highlight = {
            backdrop = true, -- Show a backdrop with hl FlashBackdrop
            matches = true, -- Highlight the search matches
            priority = 5000, -- Extmark priority
            groups = {
                match = "FlashMatch",
                current = "FlashCurrent",
                backdrop = "FlashBackdrop",
                label = "FlashLabel",
            },
        },
    },
    keys = {
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
        { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
}
