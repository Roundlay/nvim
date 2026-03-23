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
let s:bg_alt = '#050505'
let s:bg_subtle = '#0C0A09'
let s:bg_visual = '#12100E'
let s:bg_search = '#2B241D'
let s:bg_search_focus = '#4A3422'
let s:bg_diff_add = '#09100B'
let s:bg_diff_change = '#100B08'
let s:bg_diff_delete = '#120A09'
let s:bg_diff_text = '#17110B'

let s:fg = '#67625D'
let s:fg_high = '#938B82'
let s:fg_low = '#4E4944'
let s:fg_gutter = '#2F2B28'

let s:red = '#8A645F'
let s:green = '#6D7A6E'
let s:yellow = '#9A7151'
let s:blue = '#6E6761'
let s:magenta = '#746B63'
let s:cyan = '#70706A'
let s:white = '#B0A79D'
let s:amber = '#D07A34'

let s:bright_red = '#B07B72'
let s:bright_green = '#82907F'
let s:bright_yellow = '#E18A3D'
let s:bright_blue = '#8A8179'
let s:bright_magenta = '#8D8177'
let s:bright_cyan = '#85857D'

let g:terminal_color_0 = '#000000'
let g:terminal_color_1 = s:red
let g:terminal_color_2 = s:green
let g:terminal_color_3 = s:yellow
let g:terminal_color_4 = s:blue
let g:terminal_color_5 = s:magenta
let g:terminal_color_6 = s:cyan
let g:terminal_color_7 = s:fg
let g:terminal_color_8 = '#3E3934'
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
call s:hi('CursorLineNr', s:fg_high, s:bg_alt, '', '')
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
call s:hi('Question', s:amber, s:bg, '', '')
call s:hi('QuickFixLine', s:fg_high, s:bg_visual, '', '')
call s:hi('Search', s:white, s:bg_search, '', '')
call s:hi('CurSearch', '#F2E7DB', s:bg_search_focus, 'bold', '')
call s:hi('IncSearch', '#F2E7DB', s:bg_search_focus, 'bold', '')
call s:hi('SignColumn', s:fg_low, s:bg, '', '')
call s:hi('SpecialKey', s:fg_low, s:bg, '', '')
call s:hi('StatusLine', s:fg_high, s:bg_alt, '', '')
call s:hi('StatusLineNC', s:fg_low, s:bg_alt, '', '')
call s:hi('TabLine', s:fg_low, s:bg_alt, '', '')
call s:hi('TabLineFill', s:fg_low, s:bg_alt, '', '')
call s:hi('TabLineSel', s:fg_high, s:bg_visual, '', '')
call s:hi('Title', s:amber, s:bg, 'bold', '')
call s:hi('VertSplit', s:bg_subtle, s:bg, '', '')
call s:hi('Visual', '', s:bg_visual, '', '')
call s:hi('WarningMsg', s:amber, s:bg, '', '')
call s:hi('Whitespace', s:fg_gutter, s:bg, '', '')
call s:hi('WinSeparator', s:bg_subtle, s:bg, '', '')

" Syntax.
call s:hi('Comment', s:fg_low, s:bg, 'italic', '')
call s:hi('Constant', s:fg_high, s:bg, '', '')
call s:hi('String', s:fg_high, s:bg, '', '')
call s:hi('Character', s:fg_high, s:bg, '', '')
call s:hi('Number', s:fg_high, s:bg, '', '')
call s:hi('Boolean', s:fg_high, s:bg, '', '')
call s:hi('Float', s:fg_high, s:bg, '', '')
call s:hi('Identifier', s:fg, s:bg, '', '')
call s:hi('Function', s:fg_high, s:bg, '', '')
call s:hi('Statement', s:amber, s:bg, '', '')
call s:hi('Conditional', s:amber, s:bg, '', '')
call s:hi('Repeat', s:amber, s:bg, '', '')
call s:hi('Label', s:amber, s:bg, '', '')
call s:hi('Operator', s:fg, s:bg, '', '')
call s:hi('Keyword', s:amber, s:bg, '', '')
call s:hi('Exception', s:amber, s:bg, '', '')
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
call s:hi('Underlined', s:amber, s:bg, 'underline', '')
call s:hi('Ignore', s:fg_gutter, s:bg, '', '')
call s:hi('Error', s:bright_red, s:bg, 'bold', '')
call s:hi('Todo', s:fg_high, s:bg_visual, 'bold', '')

" Diff and diagnostics.
call s:hi('DiffAdd', s:green, s:bg_diff_add, '', '')
call s:hi('DiffChange', s:amber, s:bg_diff_change, '', '')
call s:hi('DiffDelete', s:red, s:bg_diff_delete, '', '')
call s:hi('DiffText', s:white, s:bg_diff_text, 'bold', '')

call s:hi('DiagnosticError', s:red, s:bg, '', '')
call s:hi('DiagnosticWarn', s:amber, s:bg, '', '')
call s:hi('DiagnosticInfo', s:fg_high, s:bg, '', '')
call s:hi('DiagnosticHint', s:fg, s:bg, '', '')
call s:hi('DiagnosticOk', s:green, s:bg, '', '')

call s:hi('DiagnosticVirtualTextError', s:red, s:bg, '', '')
call s:hi('DiagnosticVirtualTextWarn', s:amber, s:bg, '', '')
call s:hi('DiagnosticVirtualTextInfo', s:fg_high, s:bg, '', '')
call s:hi('DiagnosticVirtualTextHint', s:fg, s:bg, '', '')
call s:hi('DiagnosticVirtualTextOk', s:green, s:bg, '', '')

call s:hi('DiagnosticUnderlineError', '', '', 'undercurl', s:red)
call s:hi('DiagnosticUnderlineWarn', '', '', 'undercurl', s:amber)
call s:hi('DiagnosticUnderlineInfo', '', '', 'undercurl', s:fg_high)
call s:hi('DiagnosticUnderlineHint', '', '', 'undercurl', s:fg)
call s:hi('DiagnosticUnderlineOk', '', '', 'undercurl', s:green)

call s:hi('ErrorMsg', s:bright_red, s:bg, 'bold', '')
call s:hi('ModeMsg', s:fg_high, s:bg, '', '')
call s:hi('MoreMsg', s:amber, s:bg, '', '')
call s:hi('SpellBad', '', '', 'undercurl', s:red)
call s:hi('SpellCap', '', '', 'undercurl', s:fg_high)
call s:hi('SpellLocal', '', '', 'undercurl', s:fg)
call s:hi('SpellRare', '', '', 'undercurl', s:amber)

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
