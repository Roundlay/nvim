-- copilot.vim
-- -----------------------------------------------------------------------------

-- Note: This can't be lazy-loaded at the moment because the plugin doesn't play
-- nicely with telescope and <Tab>...?

-- return {
--     "github/copilot.vim",
--     name = "copilot",
--     enabled = true,
--     lazy = true,
--     event = "InsertEnter", 
-- }

-- copilot.lua
-- -----------------------------------------------------------------------------

-- For the Alacritty slash modified-carriage-return enjoyers out there, to get
-- <S-CR> and <C-CR> working, Alacritty needs to be configured to send escape
-- sequences Vim expects: https://stackoverflow.com/a/42461580/21730427

local uv = vim.uv or vim.loop

local function path_exists(path)
    return type(path) == "string" and path ~= "" and uv.fs_stat(path) ~= nil
end

local function resolve_shared_path(path)
    if not vim.g.is_wsl then
        return path
    end

    local drive_letter, remainder = path:match("^([A-Za-z]):[\\/](.*)$")
    if not drive_letter then
        return path
    end

    return string.format("/mnt/%s/%s", drive_letter:lower(), remainder:gsub("\\", "/"))
end

local function get_workspace_folders()
    local folder = resolve_shared_path([[C:\Users\Christopher\scoop\apps\odin\current\examples]])
    if not path_exists(folder) then
        return {}
    end
    return { folder }
end

local function get_root_dir()
    local bufname = vim.api.nvim_buf_get_name(0)
    local search_path = bufname ~= "" and vim.fs.dirname(bufname) or vim.fn.getcwd()
    local git_dir = vim.fs.find(".git", { upward = true, path = search_path })[1]

    if git_dir then
        return vim.fs.dirname(git_dir)
    end

    if bufname ~= "" then
        return vim.fs.dirname(bufname)
    end

    return vim.fn.getcwd()
end

return {
    "zbirenbaum/copilot.lua",
    build = ":Copilot auth",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
        copilot_node_command = 'node',
        -- copilot_model = "gpt-4o-copilot", // Model selection is currently not available. Default is 'gpt-4o-copilot'.
        workspace_folders = get_workspace_folders(),
        filetypes = {
            markdown = true,
        },
        server_opts_overrides = {},
        suggestion = {
            enabled = true,
            auto_trigger = true,
            debounce = 1,
            keymap = {
                accept = false,
            },
        },
        panel = {
            enabled = false,
            auto_refresh = true,
        },
        layout = {
            position = "bottom",
            ratio = 0.4,
        },
        root_dir = get_root_dir,
    },
}
