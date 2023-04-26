-- environment.lua
-- -------------------------------------------------------------------------- --

-- This file defines a Lua module that surfaces various Neovim settings,
-- including information about the OS, file paths, and directories. This helps
-- make the Neovim configuratio more portable and easier to maintain.

-- TODO
-- system vimrc file: "$VIM\sysinit.vim"
-- fall-back for $VIM: "C:/Program Files (x86)/nvim/share/nvim"

-- Create an empty table to store the global variables and settings
E = {}

-- Get the operating system name using Neovim's LibUV bindings.
local os_name = vim.loop.os_uname().sysname -- Windows_NT

function E:load_variables()
    self.is_mac      = os_name == "Darwin" -- Set to true if the operating system is macOS, otherwise false.
    self.is_linux    = os_name == "Linux" -- Set to true if the operating system is Linux, otherwise false.
    self.is_windows  = os_name == "Windows_NT" -- Set to true if the operating system is Windows, otherwise false.
    self.is_wsl      = vim.fn.has("wsl") == 1 -- Set to true if running on Windows Subsystem for Linux (WSL), otherwise false.
    self.vim_path    = vim.fn.stdpath("config") -- Get the Neovim configuration directory path.
    local path_sep   = self.is_windows and "\\" or "/"  -- Set the path separator based on the operating system.
    local home       = vim.loop.os_homedir() -- Store the user's home directory in the global table
    self.plugins_dir = self.vim_path .. path_sep .. "plugins" -- Set the Neovim modules directory path.
    self.home        = home -- Store the user's home directory in the global table
    self.data_dir    = string.format("%s/site/", vim.fn.stdpath("data")) -- Set the Neovim data directory path
    -- local home    = self.is_windows and os.getenv("USERPROFILE") or os.getenv("HOME")  -- Get the user's home directory.
    -- self.cache_dir = home .. path_sep .. ".cache" .. path_sep .. "nvim" .. path_sep  -- Set the Neovim cache directory path.
end

E:load_variables()

return E
