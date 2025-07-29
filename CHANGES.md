# CHANGES.md

Change log for completed improvements, fixes, and tweaks.

## 2025-01-29: [GIT] Fixed git push failure after rewriting commit history (files: N/A - git operations)
- Issue: `git push --force-with-lease` and `git push --set-upstream` failing with "stale info" error
- Root cause: Remote had different commit hashes after local history rewrite, --force-with-lease was rejecting due to mismatch
- Solution: Used `git push --force origin main` to override remote history with local rewritten commits
- Impact: Successfully rewrote commit history to change author information, GitHub contributor page will update within days
- Note: Force push replaces entire remote history - use with caution

## 2025-01-11: [SCRIPTS] Added tag wrapper functionality for wrapping selections with configurable tags (files: scripts.lua, keybindings.lua)
- Feature: New WrapWithTags() function to wrap text selections with custom start/end tags on separate lines
- Implementation: Supports normal mode (current line), visual mode (selected lines), and visual block mode
- Usage: <leader>w prompts for start tag (e.g., <div>, [START]) and end tag (e.g., </div>, [END])
- Behavior: Preserves indentation from the first line of selection, places tags on their own lines
- Files modified: `lua/scripts.lua:812-924` (added WrapWithTags function), `lua/keybindings.lua:155-156` (added keybindings)

## 2025-01-24: [CLIPBOARD] Fixed WSL clipboard sync interfering with separate register behavior (files: autocmds.lua)
- Issue: <leader>y and y, then p and <leader>p were pasting the same content despite separate keybindings
- Root cause: WSL clipboard sync autocmds were synchronizing default register (@) with system clipboard (+) on focus events
- Solution: Commented out WSL clipboard sync autocmds to maintain register separation
- Impact: Regular y/p now use Neovim's internal registers exclusively, <leader>y/<leader>p use system clipboard only
- Files modified: `lua/autocmds.lua:67-84`

## 2025-01-24: [CLIPBOARD] Separated Neovim clipboard from system clipboard (files: settings.lua)
- Issue: Regular y operations were copying to system clipboard, making <leader>p behave same as p
- Root cause: vim.o.clipboard = 'unnamed,unnamedplus' forces all yank operations to system clipboard
- Solution: Commented out the clipboard setting to keep Neovim's registers separate from system clipboard
- Impact: Regular y/p use Neovim's internal registers, <leader>y/<leader>p explicitly use system clipboard
- Files modified: `lua/settings.lua:164`

## 2025-01-23: [KEYBINDINGS] Diagnosed C-CR issue in Windows Terminal (files: scripts.lua, CLAUDE.md, windows-terminal-ctrl-enter-fix.json)
- Issue: C-CR keybinding not working, terminal sends LF (0x0A) instead of proper C-CR sequence
- Root cause: Windows Terminal missing keybinding for ctrl+enter despite having the action defined
- Solution: Created configuration snippet to properly bind ctrl+enter to CSI u sequence
- Added TestKey() diagnostic function in scripts.lua to debug key sequences
- Updated CLAUDE.md with principles against hacky workarounds
- Created windows-terminal-ctrl-enter-fix.json with proper terminal configuration
- Fix: Add `{"id": "User.sendInput.F8A79DCB", "keys": "ctrl+enter"}` to Windows Terminal keybindings

## 2025-01-17: [FOCUS] Enhanced window narrowing for space-constrained layouts (files: lazy-focus.lua, highlights.lua, settings.lua)
- Enhancement: ALL unfocused windows shrink to 1 character width, focused window takes remaining space
- Implementation: Added toggle variable ENABLE_EXTREME_NARROWING (default: true) for easy switching
- Visual improvement: Set purple window dividers (#68217A) with box drawing character (│)
- Impact: Maximum space utilization for active window, toggleable between extreme mode and default focus.nvim
- Usage: Set ENABLE_EXTREME_NARROWING = false in lazy-focus.lua:28 to use default 40-char minimum width

## 2025-01-17: [FOCUS] Fixed cursorline appearing when switching windows (files: lazy-focus.lua)
- Issue: Cursorline highlight appeared when moving between splits with <C-w> despite vim.o.cursorline = false
- Root cause: focus.nvim plugin had ui.cursorline = true (default), forcing cursorline in focused windows
- Solution: Set ui.cursorline = false in focus.nvim configuration to respect global cursorline setting
- Impact: Cursorline no longer appears when switching between windows/splits

## 2025-01-17: [FOCUS] Fixed numberline appearing when switching windows (files: lazy-focus.lua)
- Issue: Line numbers appeared when switching windows despite vim.o.number = false in settings
- Root cause: focus.nvim plugin had ui.number = true, overriding global settings on window focus
- Solution: Set ui.number = false in focus.nvim configuration to respect global number setting
- Impact: Line numbers no longer appear when switching between windows/splits

## 2025-01-09: [COPILOT] Fixed <C-CR> keybinding not working (files: lazy-copilot.lua)
- Issue: Only <C-\> worked for accepting Copilot suggestions; <C-CR> was not functioning
- Root cause: Duplicate `accept` keys in keymap table - second key overwrote the first
- Solution: Disabled default keymap and manually set both keybindings in config function
- Impact: Both <C-CR> and <C-\> now work for accepting Copilot suggestions
- Files modified: `lua/plugins/lazy-copilot.lua:44-47, 69-75`

## 2025-06-28: [LSP] Fixed clangd exit-code 1 on file open (files: lazy-lspconfig.lua)

- Issue: Opening any C/C++ file showed “Client clangd quit with exit code 1”.
- Root cause: The `cmd` array still contained the deprecated flags
  `--inlay-hints` and `--function-arg-placeholders` – the latter now
  requires an explicit value in clangd ≥ 20.1 and makes the server abort
  when omitted.
- Solution: Removed both obsolete flags; the same functionality is
  provided through the `InlayHints.*` settings block already present in
  the config.
- Impact: clangd starts cleanly again, inlay hints and argument
  placeholders continue to work.
- Files modified: `lua/plugins/lazy-lspconfig.lua:69-80`