" syn match myFunctionCall /\v\{/
" syn match myFunctionCall /\v\}/
syntax region myregion start=/{/ skip=/\\{/ end=/}/ oneline contains=swiftInterpolatedWrapper
" syn match myFunctionCall /\v(^\s*d4\s*::\s*proc\b|^\s*)\{/
" syn match myFunctionCall /\v\{.*\n.*\}/
" syn match myFunctionCall /\v\%(\[\d\+\]\w\+\s*\)\@<=\{/
" syn match myFunctionCall /\v\}(?!\s*:\s*\[\d\+\]\w\+\s*=)/
" syn match myFunctionCall /\%(\[\d\+\]\w\+\s*\)\@<=\{/
" syn match myFunctionCall /\}(?!\s*:\s*\[\d\+\]\w\+\s*=)/
highlight link myFunctionCall Comment
highlight link myregion Comment
