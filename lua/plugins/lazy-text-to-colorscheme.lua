return {
    "svermeulen/text-to-colorscheme",
    enabled = false,
    opts = {
        ai = {
            openai_api_key = os.getenv("OPENAI_API_KEY"),
            get_model = "gpt-4o",
            minimum_foreground_contrast = 0.5,
            enable_minimum_foreground_contrast = true,
            temperature = 0.0,
        },
        undercurl = true,
        underline = true,
        bold = true,
        italic = {
            strings = false,
            comments = false,
            operators = false,
            folds = false,
        },
        strikethrough = true,
        invert_selection = false,
        save_as_hsv = true, -- When true, T2CSave will save colors as HSV instead of hex
        invert_signs = false,
        invert_tabline = false,
        invert_intend_guides = false,
        inverse = true,
        dim_inactive = false,
        transparent_mode = false,
        overrides = {},
        default_palette = "gruvbox",
        hex_palettes = {},
        hsv_palettes = {
           {
              name = "monochrome grey theme for maximum productivity ",
              background_mode = "dark",
              background = "#1b1b1b",
              foreground = "#f5f5f5",
              accents = {
                 "#818181",
                 "#a5a5a5",
                 "#8c8c8c",
                 "#b4b4b4",
                 "#9e9e9e",
                 "#c7c7c7",
                 "#d8d8d8",
              },
           },
           {
              name = "monochrome with 032c red syntax elements like strings numbers etc",
              background_mode = "dark",
              background = {0, 0, 13}, -- #202020
              foreground = {0, 0, 74}, -- #bcbcbc
              accents = {
                 {0, 78, 83}, -- #d32f2f
                 {0, 0, 100}, -- #ffffff
                 {0, 0, 50}, -- #7f7f7f
                 {0, 0, 63}, -- #a0a0a0
                 {0, 0, 75}, -- #c0c0c0
                 {0, 0, 88}, -- #e0e0e0
                 {0, 0, 94}, -- #f0f0f0
              },
           },
        },
    },
}
