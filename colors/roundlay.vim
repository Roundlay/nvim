" Roundlay for Neovim.
" The whole scheme is built around a black field and smoked accents.

set background=dark

hi clear
if exists('syntax_on')
  syntax reset
endif

let g:colors_name = 'roundlay'

" Core palette.
let s:bg = '#000000'
let s:bg_alt = '#151514'
let s:bg_subtle = '#141613'
let s:bg_visual = '#191614'
let s:bg_search = '#1F1E1E'
let s:bg_search_focus = '#2A2827'
let s:bg_diff_add = '#141613'
let s:bg_diff_change = '#1F1E1E'
let s:bg_diff_delete = '#191614'
let s:bg_diff_text = '#2A2827'

let s:fg = '#4A4946'
let s:fg_high = '#55575A'
let s:fg_low = '#302E2D'
let s:fg_gutter = '#201F1E'

let s:red = '#59413B'
let s:green = '#4C5C4A'
let s:yellow = '#4A4946'
let s:blue = '#55575A'
let s:magenta = '#4A4946'
let s:cyan = '#55575A'
let s:white = '#55575A'
let s:accent = s:fg

let s:bright_red = '#59413B'
let s:bright_green = '#4C5C4A'
let s:bright_yellow = '#55575A'
let s:bright_blue = '#55575A'
let s:bright_magenta = '#4A4946'
let s:bright_cyan = '#55575A'

let g:terminal_color_0 = s:bg
let g:terminal_color_1 = s:red
let g:terminal_color_2 = s:green
let g:terminal_color_3 = s:yellow
let g:terminal_color_4 = s:blue
let g:terminal_color_5 = s:magenta
let g:terminal_color_6 = s:cyan
let g:terminal_color_7 = s:fg
let g:terminal_color_8 = s:fg_low
let g:terminal_color_9 = s:bright_red
let g:terminal_color_10 = s:bright_green
let g:terminal_color_11 = s:bright_yellow
let g:terminal_color_12 = s:bright_blue
let g:terminal_color_13 = s:bright_magenta
let g:terminal_color_14 = s:bright_cyan
let g:terminal_color_15 = s:white

function! s:hi(group, fg, bg, style, sp) abort
  let l:parts = ['highlight', a:group]
  let l:gui_style = empty(a:style) ? 'NONE' : a:style
  let l:cterm_style = empty(a:style) ? 'NONE' : substitute(a:style, 'undercurl', 'underline', 'g')

  if !empty(a:fg)
    call add(l:parts, 'guifg=' . a:fg)
  endif
  if !empty(a:bg)
    call add(l:parts, 'guibg=' . a:bg)
  endif

  call add(l:parts, 'gui=' . l:gui_style)
  call add(l:parts, 'cterm=' . l:cterm_style)
  execute join(l:parts, ' ')

  if !empty(a:sp)
    execute 'highlight' a:group 'guisp=' . a:sp
  endif
endfunction

" Editor frame.
call s:hi('Normal', s:fg, s:bg, '', '')
call s:hi('NormalNC', s:fg, s:bg, '', '')
call s:hi('NormalFloat', s:fg, s:bg_alt, '', '')
call s:hi('FloatBorder', s:fg_low, s:bg_alt, '', '')
call s:hi('FloatTitle', s:fg_high, s:bg_alt, '', '')
call s:hi('ColorColumn', '', s:bg_alt, '', '')
call s:hi('Conceal', s:fg_low, s:bg, '', '')
call s:hi('Cursor', s:bg, s:fg_high, '', '')
call s:hi('CursorColumn', '', s:bg_alt, '', '')
call s:hi('CursorLine', '', s:bg_alt, '', '')
call s:hi('CursorLineNr', s:fg_high, s:bg, 'bold', '')
call s:hi('Directory', s:fg_high, s:bg, '', '')
call s:hi('EndOfBuffer', s:fg_gutter, s:bg, '', '')
call s:hi('FoldColumn', s:fg_low, s:bg, '', '')
call s:hi('Folded', s:fg_low, s:bg_subtle, '', '')
call s:hi('LineNr', s:fg_gutter, s:bg, '', '')
call s:hi('MatchParen', s:fg_high, s:bg_visual, 'bold', '')
call s:hi('NonText', s:fg_gutter, s:bg, '', '')
call s:hi('Pmenu', s:fg, s:bg_alt, '', '')
call s:hi('PmenuSel', s:fg_high, s:bg_visual, '', '')
call s:hi('PmenuSbar', '', s:bg_subtle, '', '')
call s:hi('PmenuThumb', '', s:fg_low, '', '')
call s:hi('Question', s:fg_high, s:bg, '', '')
call s:hi('QuickFixLine', s:fg_high, s:bg_visual, '', '')
call s:hi('Search', s:white, s:bg_search, '', '')
call s:hi('CurSearch', s:white, s:bg_search_focus, 'bold', '')
call s:hi('IncSearch', s:white, s:bg_search_focus, 'bold', '')
call s:hi('SignColumn', s:fg_low, s:bg, '', '')
call s:hi('SpecialKey', s:fg_low, s:bg, '', '')
call s:hi('StatusLine', s:fg_high, s:bg_alt, '', '')
call s:hi('StatusLineNC', s:fg_low, s:bg_alt, '', '')
call s:hi('TabLine', s:fg_low, s:bg_alt, '', '')
call s:hi('TabLineFill', s:fg_low, s:bg_alt, '', '')
call s:hi('TabLineSel', s:fg_high, s:bg_visual, '', '')
call s:hi('Title', s:accent, s:bg, 'bold', '')
call s:hi('VertSplit', s:bg_subtle, s:bg, '', '')
call s:hi('Visual', '', s:bg_visual, '', '')
call s:hi('WarningMsg', s:accent, s:bg, '', '')
call s:hi('Whitespace', s:fg_gutter, s:bg, '', '')
call s:hi('WinSeparator', s:bg_subtle, s:bg, '', '')

" Syntax.
call s:hi('Comment', s:fg_low, s:bg, 'italic', '')
call s:hi('Constant', s:fg, s:bg, '', '')
call s:hi('String', s:fg, s:bg, '', '')
call s:hi('Character', s:fg, s:bg, '', '')
call s:hi('Number', s:fg, s:bg, '', '')
call s:hi('Boolean', s:fg, s:bg, '', '')
call s:hi('Float', s:fg, s:bg, '', '')
call s:hi('Identifier', s:fg, s:bg, '', '')
call s:hi('Function', s:fg_high, s:bg, '', '')
call s:hi('Statement', s:accent, s:bg, '', '')
call s:hi('Conditional', s:accent, s:bg, '', '')
call s:hi('Repeat', s:accent, s:bg, '', '')
call s:hi('Label', s:accent, s:bg, '', '')
call s:hi('Operator', s:fg, s:bg, '', '')
call s:hi('Keyword', s:accent, s:bg, '', '')
call s:hi('Exception', s:accent, s:bg, '', '')
call s:hi('PreProc', s:fg_high, s:bg, '', '')
call s:hi('Include', s:fg_high, s:bg, '', '')
call s:hi('Define', s:fg_high, s:bg, '', '')
call s:hi('Macro', s:fg_high, s:bg, '', '')
call s:hi('PreCondit', s:fg_high, s:bg, '', '')
call s:hi('Type', s:fg_high, s:bg, '', '')
call s:hi('StorageClass', s:fg_high, s:bg, '', '')
call s:hi('Structure', s:fg_high, s:bg, '', '')
call s:hi('Typedef', s:fg_high, s:bg, '', '')
call s:hi('Special', s:fg, s:bg, '', '')
call s:hi('SpecialChar', s:fg, s:bg, '', '')
call s:hi('Tag', s:fg_high, s:bg, '', '')
call s:hi('Delimiter', s:fg_low, s:bg, '', '')
call s:hi('SpecialComment', s:fg_low, s:bg, 'italic', '')
call s:hi('Debug', s:red, s:bg, '', '')
call s:hi('Underlined', s:fg_high, s:bg, 'underline', '')
call s:hi('Ignore', s:fg_gutter, s:bg, '', '')
call s:hi('Error', s:bright_red, s:bg, 'bold', '')
call s:hi('Todo', s:fg_high, s:bg_visual, 'bold', '')

" Diff and diagnostics.
call s:hi('DiffAdd', s:green, s:bg_diff_add, '', '')
call s:hi('DiffChange', s:fg_high, s:bg_diff_change, '', '')
call s:hi('DiffDelete', s:red, s:bg_diff_delete, '', '')
call s:hi('DiffText', s:white, s:bg_diff_text, 'bold', '')

call s:hi('DiagnosticError', s:red, s:bg, '', '')
call s:hi('DiagnosticWarn', s:accent, s:bg, '', '')
call s:hi('DiagnosticInfo', s:fg_high, s:bg, '', '')
call s:hi('DiagnosticHint', s:fg, s:bg, '', '')
call s:hi('DiagnosticOk', s:green, s:bg, '', '')

call s:hi('DiagnosticVirtualTextError', s:red, s:bg, '', '')
call s:hi('DiagnosticVirtualTextWarn', s:accent, s:bg, '', '')
call s:hi('DiagnosticVirtualTextInfo', s:fg_high, s:bg, '', '')
call s:hi('DiagnosticVirtualTextHint', s:fg, s:bg, '', '')
call s:hi('DiagnosticVirtualTextOk', s:green, s:bg, '', '')

call s:hi('DiagnosticUnderlineError', '', '', 'undercurl', s:red)
call s:hi('DiagnosticUnderlineWarn', '', '', 'undercurl', s:accent)
call s:hi('DiagnosticUnderlineInfo', '', '', 'undercurl', s:fg_high)
call s:hi('DiagnosticUnderlineHint', '', '', 'undercurl', s:fg)
call s:hi('DiagnosticUnderlineOk', '', '', 'undercurl', s:green)

call s:hi('ErrorMsg', s:bright_red, s:bg, 'bold', '')
call s:hi('ModeMsg', s:fg_high, s:bg, '', '')
call s:hi('MoreMsg', s:fg_high, s:bg, '', '')
call s:hi('SpellBad', '', '', 'undercurl', s:red)
call s:hi('SpellCap', '', '', 'undercurl', s:fg_high)
call s:hi('SpellLocal', '', '', 'undercurl', s:fg)
call s:hi('SpellRare', '', '', 'undercurl', s:accent)

" Treesitter and LSP semantic links.
hi! link @comment Comment
hi! link @constant Constant
hi! link @string String
hi! link @string.escape SpecialChar
hi! link @number Number
hi! link @boolean Boolean
hi! link @function Function
hi! link @function.call Function
hi! link @keyword Keyword
hi! link @keyword.operator Operator
hi! link @operator Operator
hi! link @type Type
hi! link @type.builtin Type
hi! link @variable Identifier
hi! link @variable.builtin Identifier
hi! link @property Identifier
hi! link @punctuation.delimiter Delimiter
hi! link @punctuation.bracket Delimiter
