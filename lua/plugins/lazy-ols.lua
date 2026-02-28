-- ols

-- Create a user environment variable 'ODIN_ROOT' that points to the Odin
-- directory so that OLS can index the core and vendor libraries.

return {
    "DanielGavin/ols",
    condition = function() if (vim.g.vscode) then return false end end,
    lazy = true,
    ft = "odin",
}
