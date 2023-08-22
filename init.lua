-- init.lua
-- -------------------------------------------------------------------------- --

-- Benchmarks
-- -------------------------------------------------------------------------- --

-- Lazy Benchmark (26-07-23)
-- Lazy Profile: Startuptime: 39.72ms
-- Environment: Windows 11 -> Alacritty (Administrator) -> Clink -> NVIM v0.9.0
-- Command: `hyperfine --warmup 5 "nvim init.lua --headless +qa"`

-- Vim-Plug Benchmark (22-04-23)
-- Environment: Windows 11 -> Alacritty (Administrator) -> Clink -> NVIM v0.9.0
-- Command: `hyperfine --warmup 5 "nvim init.lua --headless +qa"`
-- Time (mean ± σ):    279.6 ms ±   6.2 ms  [User: 108.4 ms, System: 201.6 ms]
-- Range (min … max):  274.5 ms … 295.2 ms  10 runs

-- Initialisation
-- -------------------------------------------------------------------------- --

-- Set Neovim settings
require("settings")

-- Bind custom keybindings
require("keybindings")

-- Plug in Vim-Plug
-- require("plug")

-- Initialise Lazy
require("lazy-init")

-- Light up custom highlights
require("highlights")

-- I'm just not that funny: call scripts.lua.
require("scripts")
