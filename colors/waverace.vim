" Waverace for Neovim.
" Inspired by the Wave Race 64 box art: cobalt sky, foam white,
" sunlit yellow, cartridge red, and arcade rider accents.

set background=dark

hi clear
if exists('syntax_on')
  syntax reset
endif

let g:colors_name = 'waverace'

" Core palette.
let s:bg = '#24366F'
let s:bg_alt = '#2E4690'
let s:bg_subtle = '#20305F'
let s:bg_visual = '#3456B0'
let s:bg_search = '#F4C64C'
let s:bg_search_focus = '#FFD87A'
let s:bg_diff_add = '#203D2C'
let s:bg_diff_change = '#243F73'
let s:bg_diff_delete = '#4A2628'
let s:bg_diff_text = '#4C73D0'

let s:fg = '#EAF2FF'
let s:fg_high = '#FFFCEF'
let s:fg_low = '#9FB2E8'
let s:fg_gutter = '#7389C9'

let s:red = '#F05B3D'
let s:green = '#9AD94B'
let s:yellow = '#F4C64C'
let s:blue = '#76B8FF'
let s:magenta = '#E492E8'
let s:cyan = '#88E6FF'
let s:white = '#FFFCEF'
let s:accent = s:yellow

let s:bright_red = '#FF7A61'
let s:bright_green = '#B9F06C'
let s:bright_yellow = '#FFD87A'
let s:bright_blue = '#98CCFF'
let s:bright_magenta = '#F0B1F5'
let s:bright_cyan = '#B0F1FF'

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
call s:hi('FloatTitle', s:accent, s:bg_alt, 'bold', '')
call s:hi('ColorColumn', '', s:bg_subtle, '', '')
call s:hi('Conceal', s:fg_low, s:bg, '', '')
call s:hi('Cursor', s:bg, s:fg_high, '', '')
call s:hi('CursorColumn', '', s:bg_subtle, '', '')
call s:hi('CursorLine', '', s:bg_subtle, '', '')
call s:hi('CursorLineNr', s:fg_high, s:bg, 'bold', '')
call s:hi('Directory', s:cyan, s:bg, '', '')
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
call s:hi('Question', s:green, s:bg, '', '')
call s:hi('QuickFixLine', s:fg_high, s:bg_visual, '', '')
call s:hi('Search', s:bg, s:bg_search, 'bold', '')
call s:hi('CurSearch', s:bg, s:bg_search_focus, 'bold', '')
call s:hi('IncSearch', s:bg, s:bg_search_focus, 'bold', '')
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
call s:hi('WarningMsg', s:yellow, s:bg, '', '')
call s:hi('Whitespace', s:fg_gutter, s:bg, '', '')
call s:hi('WinSeparator', s:bg_subtle, s:bg, '', '')

" Syntax.
call s:hi('Comment', s:fg_low, s:bg, 'italic', '')
call s:hi('Constant', s:fg_high, s:bg, '', '')
call s:hi('String', s:white, s:bg, '', '')
call s:hi('Character', s:white, s:bg, '', '')
call s:hi('Number', '#FFDFA6', s:bg, '', '')
call s:hi('Boolean', '#FFDFA6', s:bg, '', '')
call s:hi('Float', '#FFDFA6', s:bg, '', '')
call s:hi('Identifier', s:fg, s:bg, '', '')
call s:hi('Function', s:cyan, s:bg, '', '')
call s:hi('Statement', s:accent, s:bg, '', '')
call s:hi('Conditional', s:accent, s:bg, '', '')
call s:hi('Repeat', s:accent, s:bg, '', '')
call s:hi('Label', s:accent, s:bg, '', '')
call s:hi('Operator', s:fg, s:bg, '', '')
call s:hi('Keyword', s:accent, s:bg, '', '')
call s:hi('Exception', s:red, s:bg, '', '')
call s:hi('PreProc', s:magenta, s:bg, '', '')
call s:hi('Include', s:magenta, s:bg, '', '')
call s:hi('Define', s:magenta, s:bg, '', '')
call s:hi('Macro', s:magenta, s:bg, '', '')
call s:hi('PreCondit', s:magenta, s:bg, '', '')
call s:hi('Type', s:green, s:bg, '', '')
call s:hi('StorageClass', s:green, s:bg, '', '')
call s:hi('Structure', s:green, s:bg, '', '')
call s:hi('Typedef', s:green, s:bg, '', '')
call s:hi('Special', s:blue, s:bg, '', '')
call s:hi('SpecialChar', s:blue, s:bg, '', '')
call s:hi('Tag', s:cyan, s:bg, '', '')
call s:hi('Delimiter', s:fg_low, s:bg, '', '')
call s:hi('SpecialComment', s:fg_low, s:bg, 'italic', '')
call s:hi('Debug', s:red, s:bg, '', '')
call s:hi('Underlined', s:cyan, s:bg, 'underline', '')
call s:hi('Ignore', s:fg_gutter, s:bg, '', '')
call s:hi('Error', s:bright_red, s:bg, 'bold', '')
call s:hi('Todo', s:bg, s:bg_search, 'bold', '')

" Diff and diagnostics.
call s:hi('DiffAdd', s:green, s:bg_diff_add, '', '')
call s:hi('DiffChange', s:blue, s:bg_diff_change, '', '')
call s:hi('DiffDelete', s:red, s:bg_diff_delete, '', '')
call s:hi('DiffText', s:fg_high, s:bg_diff_text, 'bold', '')

call s:hi('DiagnosticError', s:red, s:bg, '', '')
call s:hi('DiagnosticWarn', s:yellow, s:bg, '', '')
call s:hi('DiagnosticInfo', s:blue, s:bg, '', '')
call s:hi('DiagnosticHint', s:cyan, s:bg, '', '')
call s:hi('DiagnosticOk', s:green, s:bg, '', '')

call s:hi('DiagnosticVirtualTextError', s:red, s:bg, '', '')
call s:hi('DiagnosticVirtualTextWarn', s:yellow, s:bg, '', '')
call s:hi('DiagnosticVirtualTextInfo', s:blue, s:bg, '', '')
call s:hi('DiagnosticVirtualTextHint', s:cyan, s:bg, '', '')
call s:hi('DiagnosticVirtualTextOk', s:green, s:bg, '', '')

call s:hi('DiagnosticUnderlineError', '', '', 'undercurl', s:red)
call s:hi('DiagnosticUnderlineWarn', '', '', 'undercurl', s:yellow)
call s:hi('DiagnosticUnderlineInfo', '', '', 'undercurl', s:blue)
call s:hi('DiagnosticUnderlineHint', '', '', 'undercurl', s:cyan)
call s:hi('DiagnosticUnderlineOk', '', '', 'undercurl', s:green)

call s:hi('ErrorMsg', s:bright_red, s:bg, 'bold', '')
call s:hi('ModeMsg', s:fg_high, s:bg, '', '')
call s:hi('MoreMsg', s:green, s:bg, '', '')
call s:hi('SpellBad', '', '', 'undercurl', s:red)
call s:hi('SpellCap', '', '', 'undercurl', s:blue)
call s:hi('SpellLocal', '', '', 'undercurl', s:cyan)
call s:hi('SpellRare', '', '', 'undercurl', s:magenta)

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
