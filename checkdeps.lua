-- Save this as check_nvim_deps.lua
local function check_executable(cmd)
    local handle = io.popen('where ' .. cmd .. ' 2>nul')
    if handle then
        local result = handle:read('*a')
        handle:close()
        return result ~= ''
    end
    return false
end

local function print_status(name, status)
    print(string.format('%-20s: %s', name, status and '✓ Found' or '× Not found'))
end

local function check_plugin_health()
    -- Check core dependencies
    print('\n=== Core Dependencies ===')
    print_status('Node.js', check_executable('node'))
    print_status('npm', check_executable('npm'))
    print_status('git', check_executable('git'))

    -- Print PATH
    print('\n=== Environment ===')
    print('PATH:', os.getenv('PATH'))

    -- Check plugin directories
    print('\n=== Plugin Directories ===')
    local config_path = vim.fn.stdpath('config')
    local data_path = vim.fn.stdpath('data')
    print('Config path:', config_path)
    print('Data path:', data_path)
    
    -- Check specific plugin paths
    local plugin_paths = {
        copilot = data_path .. '\\site\\pack\\*\\start\\*copilot.vim',
        telescope = data_path .. '\\site\\pack\\*\\start\\*telescope.nvim'
    }
    
    for plugin, path in pairs(plugin_paths) do
        local exists = vim.fn.glob(path) ~= ''
        print_status(plugin, exists)
    end

    -- Check Node.js version if available
    if check_executable('node') then
        local handle = io.popen('node --version')
        if handle then
            local version = handle:read('*a')
            handle:close()
            print('\nNode.js version:', version)
        end
    end
end

check_plugin_health()
