return {
    'unblevable/quick-scope',
    enabled = true,
    init = function ()
        vim.cmd [[ let g:qs_highlight_on_keys = ['f', 'F'] ]] -- Highlight search terms on 'f' and 'F' keypresses.
        vim.cmd [[ highlight QuickScopePrimary guifg=#c82491 gui=bold cterm=bold ]]
        vim.cmd [[ highlight QuickScopeSecondary guifg=#afff00 ]]
    end
}
