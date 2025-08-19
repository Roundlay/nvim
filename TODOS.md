# TODOS.md

- - -

- [ ] In-line comment symbols (//) don't respect the line-break rules in the "Wrappin" script. We need to ensure that we detect in-line comment symbols (e.g. //, --, #, and so on) when they're wrapped in quotation marks, brackets, backticks (single and code-fenced), etc. Notice that the lines on the comment line don't respect the line length rules anymore. We still want to preserve the old comment parsing behaviour for standalone comments.

Examples:

```
Hopefully an analysis of this [LSX1] data-structure will help us understand how to map it to the dependency tree we manually derived. The manually derived resource dependency tree is below in the section marked "DEPENDENCY TREE". I've included comments (` // ...`) above lines that I was able to manually cross-reference with the DEPENDENCY TREE data.
```

Becomes...

```
Hopefully an analysis of this [LSX1] data-structure will help us understand how
to map it to the dependency tree we manually derived. The manually derived
resource dependency tree is below in the section marked "DEPENDENCY TREE". I've
included comments (`
// ...`) above lines that I was able to manually cross-reference with the DEPENDENCY TREE data.
```

But it should be:

```
Hopefully an analysis of this [LSX1] data-structure will help us understand how
to map it to the dependency tree we manually derived. The manually derived
resource dependency tree is below in the section marked "DEPENDENCY TREE". I've
included comments (`// ...`) above lines that I was able to manually
cross-reference with the DEPENDENCY TREE data.
```


- - -

- [ ] FIX: When opening C files from Telescope I see this error message: "Error detected while processing InsertLeave Autocommands for "*.c": method textDocument/hover is not supported by any of the servers registered for the current buffer"

- - -

- [ ] TODO: Can we update dd so that it doesn't overwrite the yank register if we dd a blank line? E.g. often we dd a line, and then want to remove the line above it, but we want to keep the first dd in a register.
- [ ] TODO: Improve startup performance (current goal: <50ms)
    - [ ] TODO: Come up with a robust benchmarking framework.
- [ ] TODO: 2025-06-25 13:44:49 Add highlight overrides for C (clangd?) in after/queries/c/ (?).
    - E.g. highlights.scm or something like that. See after/queries/odin/ for examples.
        - Like the Odin example, we want to dim opening and closing curly braces (but not for e.g. inline arrays, just for structs, functions, etc.).
- [ ] TODO: 2025-06-09 14:12:10 The truncated path logic we use in the status line doesn't work when we're using Neovim from within WSL, probably because it's hardcoded for Windows?
- [!] TODO: Diagnostics script still breaks in Python files, where many diagnostics can remain around on certain lines, never being cleared up
- [ ] TODO: Reduce API calls in line number formatter - cache values and update only when changed
- [ ] TODO: Clean up configuration files
- [ ] TODO: Fix Markdown nested dot point highlighting (infinite nesting depth)
- [ ] TODO: When buffer width < statusline/Lualine elements width, fix truncation characters ('<' etc.)
- [ ] TODO: Find a way to allow using this configuration within WSL2
- [ ] TODO: When deleting certain lines with `dd`, not all, usually after some line number half way down the screen (unclear), or within certain nested blocks, something like that, lines above the one being deleted seem to shift up a line then back to the right position. This appears like a flash but upon close inspection you can see lines jump up then down again. Seems to only happen when the zoom level is lower than the default zoom level. That is, when I hit Control+Minus one or more times.
    - This was caused by the indent highlight plugin, which you disabled because of it...
- [ ] TODO: Add support for plugin style setup functions within package managers (e.g., Lazy) for my custom scripts.

- - -

- [ ] TODO: 2025-06-08 13:49:41 Just saw this error message... What's this about?

```
clipboard: No provider. Try ":checkhealth" or ":h clipboard".
E353: Nothing in register +
Press ENTER or type command to continue                                                                               Error executing lua callback: ...im-extracted/usr/share/nvim/runtime/lua/vim/lsp/sync.lua:195: attempt to get length o
f local 'prev_line' (a nil value)
stack traceback:
        ...im-extracted/usr/share/nvim/runtime/lua/vim/lsp/sync.lua:195: in function 'compute_end_range'
        ...im-extracted/usr/share/nvim/runtime/lua/vim/lsp/sync.lua:401: in function 'compute_diff'
        ...d/usr/share/nvim/runtime/lua/vim/lsp/_changetracking.lua:106: in function 'incremental_changes'
        ...d/usr/share/nvim/runtime/lua/vim/lsp/_changetracking.lua:311: in function 'send_changes_for_group'
        ...d/usr/share/nvim/runtime/lua/vim/lsp/_changetracking.lua:348: in function 'send_changes'
        ...in/nvim-extracted/usr/share/nvim/runtime/lua/vim/lsp.lua:977: in function <...in/nvim-extracted/usr/share/n
vim/runtime/lua/vim/lsp.lua:971>
Press ENTER or type command to continue  
```

- - -
