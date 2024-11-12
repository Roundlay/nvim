return {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
        search = {
            exclude = {
              "notify",
              "cmp_menu",
              "flash_prompt",
            },
        },
        jump = {
            nohlsearch = true,
        },
        modes = {
            search = {
                enabled = false,
                highlight = { backdrop = true },
            },
            char = {
                jump_labels = true
            },
        },
        label = {
            uppercase = true,
            style = "overlay", ---@type "eol" | "overlay" | "right_align" | "inline"
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
    -- stylua: ignore
    keys = {
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
        { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
        -- { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
        -- { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
        -- { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
}
