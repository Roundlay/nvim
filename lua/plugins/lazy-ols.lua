-- ols

-- Create a user environment variable 'ODIN_ROOT' that points to the Odin
-- directory so that OLS can index the core and vendor libraries.

return {
    "DanielGavin/ols",
    -- name = "ols",
    enabled = true,
    lazy = true,
    ft = "odin",
}
