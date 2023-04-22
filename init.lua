-- init.lua

-- Benchmarks

-- Lazy Benchmark (22-04-23)
-- Environment: Windows 11 -> Alacritty (Administrator) -> Clink -> NVIM v0.9.0
-- Command: `hyperfine --warmup 5 "nvim init.lua --headless +qa"`
-- Time (mean ± σ):   135.6 ms ±   1.0 ms    [User: 59.0 ms, System: 89.7 ms]
-- Range (min … max): 133.6 ms … 137.4 ms    17 runs

-- Vim-Plug Benchmark (22-04-23)
-- Environment: Windows 11 -> Alacritty (Administrator) -> Clink -> NVIM v0.9.0
-- Command: `hyperfine --warmup 5 "nvim init.lua --headless +qa"`
-- Time (mean ± σ):   279.6 ms ±   6.2 ms    [User: 108.4 ms, System: 201.6 ms]
-- Range (min … max): 274.5 ms … 295.2 ms    10 runs

-- Notes

-- Initialise `settings.lua` before `lazy-init.lua` to ensure that the tab key
-- works normally alongside `copilot.vim` and `copilot.lua`.

-- Plug in Vim-Plug
-- require("plugins")

-- Set Neovim settings
require("settings")

-- Initialise lazy.nvim
require("lazy-init")

-- Light up custom highlights
require("highlights")

-- Bind custom keybindings
require("keybindings")

