return {
    'unblevable/quick-scope',
    enabled = true,
    init = function ()
        vim.cmd [[ highlight QuickScopePrimary guifg=#c82491 gui=bold cterm=bold ]]
        vim.cmd [[ highlight QuickScopeSecondary guifg=#afff00 ]]
    end
}
