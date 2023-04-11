-- environment.lua

-- This file defines a `global` Lua module that provides various global variables
-- and settings for Neovim, including information about the operating system,
-- file paths, and directories. This helps in making the Neovim configuration
-- more portable and easier to maintain.

local global = {} -- Create an empty table to store the global variables and settings
local os_name = vim.loop.os_uname().sysname -- Get the operating system name using Neovim's LibUV bindings.

-- Initialise various global variables and settings based on the detected
-- operating system and environment.
function global:load_variables()
    self.is_mac = os_name == "Darwin" -- Set to true if the operating system is macOS, otherwise false.
    self.is_linux = os_name == "Linux" -- Set to true if the operating system is Linux, otherwise false.
    self.is_windows = os_name == "Windows_NT" -- Set to true if the operating system is Windows, otherwise false.
    self.is_wsl = vim.fn.has("wsl") == 1 -- Set to true if running on Windows Subsystem for Linux (WSL), otherwise false.
    self.vim_path = vim.fn.stdpath("config") -- Get the Neovim configuration directory path.
    local path_sep = self.is_windows and "\\" or "/"  -- Set the path separator based on the operating system.
    local home = vim.loop.os_homedir() -- Store the user's home directory in the global table
    self.plugins_dir = self.vim_path .. path_sep .. "plugins" -- Set the Neovim modules directory path.
    self.home = home -- Store the user's home directory in the global table
    self.data_dir = string.format("%s/site/", vim.fn.stdpath("data")) -- Set the Neovim data directory path
    -- local home = self.is_windows and os.getenv("USERPROFILE") or os.getenv("HOME")  -- Get the user's home directory.
    -- self.cache_dir = home .. path_sep .. ".cache" .. path_sep .. "nvim" .. path_sep  -- Set the Neovim cache directory path.
end

global:load_variables() -- Call the `load_variables` function to initialize the global variables and settings

return global -- Return the global table, so it can be used by other Lua modules
