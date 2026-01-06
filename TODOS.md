# TODOs

## Treesitter Auto-Install CLI Guard (2026-01-06)

- [X] Skip auto-install for parsers that require grammar generation when `tree-sitter` or `node` is missing.
- [~] Install `tree-sitter` CLI + NodeJS if Swift Treesitter highlighting is needed.

## Treesitter Minimal Footprint (2026-01-06)

- [X] Disable auto-install and pin a minimal `ensure_installed` parser list.

## Markdown Highlight Quirks (2026-01-06)

- [X] Keep inline code highlighting inside raw HTML-style tag blocks.
- [X] Suppress underline styling on bracketed markers like `[+]` when not followed by link/reference syntax.

## OLS LSP Init Errors (2026-01-05)

- [X] Select an executable `ols` command (PATH-first, then platform fallback) to avoid invalid cmd errors.
- [X] Provide Odin root/command hints and `ODIN_ROOT` env so OLS can initialize without PATH-dependent failures.

## Commit Message Scrub Helper (2026-01-01)

- [X] Add helper script to report commits containing configurable substrings.
- [X] Add rewrite mode that strips matching lines via git filter-branch.

## Scrolling Hitching Investigation (2025-12-30) — RESOLVED

**Symptom:** Periodic micro-hitching and tearing-like artifacts during continuous scrolling.

### Resolution Summary

- [X] **ROOT CAUSE IDENTIFIED:** `vim.o.showcmd = false` **combined with tmux pane splits** caused tearing artifacts.
    - The issue only manifests when Neovim runs in a tmux split (horizontal or vertical).
    - Single tmux window (no splits) does not exhibit the tearing.
    - Likely cause: `showcmd=false` alters redraw timing/batching in a way that conflicts with tmux's pane synchronization.
- [X] **FIX APPLIED:** Commented out `showcmd = false` (line 75), leaving default `true`.
- [X] **VERIFIED:** Full config now scrolls without tearing. Baseline hitching (~3.5/5) remains due to WSL2/terminal overhead.

### Investigation Method

Bisection testing with isolated test inits (A-Z series) progressively narrowed:
1. Full config vs `--clean -u NONE` → config-induced (tearing gone with clean)
2. Plugins vs settings → `settings.lua` caused tearing (Test J)
3. Display options cluster → `laststatus`/`showcmd`/`showmode` (Test R → V)
4. Individual settings → `showcmd = false` (Test Y)
5. Post-fix observation: issue specific to **tmux splits**, not standalone tmux windows

### Collateral Fixes

- [X] Fixed `vim.g` vs `vim.o` API misuse for `hidden`, `mouse`, `timeoutlen`, `ttimeoutlen`.
- [X] Removed no-op `vim.g.redrawtime = 1`.

### Remaining Baseline Hitching

The ~3.5/5 hitching present even with `--clean -u NONE` is environmental (WSL2 display server, terminal PTY latency). Not addressable via Neovim config.

### Future Optimization Opportunities (Optional)

- [ ] 2.0 - `pretty_line_numbers` optimization (hoist globals, pre-compute formats, avoid regex in hot path).
- [ ] 3.0 - Lualine event-driven refresh (replace 1000ms timer with autocmd-based updates).
- [ ] 4.0 - `custom_diagnostics` optimization (cache diagnostics, reduce `redraw!` calls).
- [ ] 5.0 - `c_return_types` optimization (file size threshold, aggressive debounce).

---

- [X] 2025-12-21 Override inactive LSP semantic groups to keep inactive C regions fully highlighted.
- [X] 2025-12-21 Re-enable LSP stack (mason + lspconfig) and centralize server lists.
- [ ] Analyse perf. log output!
- [!] 2025-11-10 tmux SIXEL guard still misbehaves; repro and align detection logic with tmux#4488 fix.
- [>] Remove the tmux SIXEL workaround once tmux 3.6+ (with tmux#4488) is released and confirmed stable across WSL/Linux terminals.
- [X] 2025-11-06 Fix lualine truncated filepath compression (Unix separators, Windows drive casing, UNNAMED formatting).
- [X] 2025-11-06 Migrate swift.nvim SourceKit wiring to `vim.lsp.config` to remove nvim-lspconfig deprecation warnings.
- [X] 2025-11-11 Clamp rdpad workspace LF enforcement to the buffer-local `fileformat` option to stop BufReadPost errors when opening Swift packages on Windows.
- [X] 2025-12-03 Harden LSP go-to-definition split handler (per-client encoding, tab-local reuse, clearer errors).
- [X] 2025-12-22 Fix lazy-lspconfig spec table syntax + restore server list loop variable.
- [X] 2025-12-22 Restore Lazy plugin specs import after removing perf framework.
- [X] 2025-12-22 Inline mason-lspconfig server list after removing lsp.servers module.
- [X] 2025-12-22 Add Mason bin path injection so lua_ls resolves in WSL.
- [X] 2025-12-22 Add WSL lua_ls fallback path when libbfd-2.38 is missing.
- [X] 2025-12-22 Prefer non-WSL Mason bin for lua_ls when libbfd-2.38 is absent.
- [X] 2025-12-22 Ensure PATH prioritizes non-WSL Mason bin when lua_ls fallback is needed.
- [X] 2025-12-22 Reorder PATH entries so Mason bins are deduped and preferred bin is first.
- [X] 2025-12-26 Stop LSP hover keymap from overriding custom paragraph jump on `K`.
- [X] 2025-12-26 Reapply `K` paragraph jump on LspAttach to override late buffer maps.
- [X] 2025-12-26 Reassert paragraph jump maps for already-attached LSP buffers (WSL default LSP maps).
- [X] 2025-12-26 Style LSP hover float with VSCode light palette (border + winhighlight).
- [X] 2025-12-26 Map NormalFloat in hover winhighlight to override dark popup background.
- [X] 2025-12-26 Replace vim.lsp.buf.hover to apply VSCode light winhighlight on the created float.
- [X] 2025-12-26 Extend hover winhighlight mappings for markdown/treesitter groups + cap width at 80.
- [X] 2025-12-26 Use block glyph borders for hover float (▀/▄/█).
- [X] 2025-12-26 Adjust hover border corners to full blocks with top half-block run.
- [X] 2025-12-26 Add inner padding by widening hover side borders with trailing space.
- [X] 2025-12-26 Add inner padding by prefix/suffix spaces on hover contents.
- [X] 2025-12-26 Apply VSCode light hover palette to Blink completion/doc/signature popups.
- [X] 2025-12-26 Align hover + Blink text colors with VSCode light palette values.
- [X] 2025-12-26 Pull popup palette from vscode.nvim light colors and sync Blink/LSP mappings.
- [X] 2025-12-26 Ensure LSP hover mapping works after opening files post-startup.
- [X] 2025-12-26 Read VSCode light palette with noautocmd background swap to avoid theme break.
- [X] 2025-12-26 Load VSCode light palette in isolated env to avoid touching background.
- [X] 2025-12-26 Map popup syntax groups to light palette and tune Blink kind colors.
- [X] 2025-12-26 Simplify hover popup to uniform text color by disabling syntax/TS.
- [X] 2025-12-26 Size hover popup to min(buffer width, 160) and max 1/3 buffer height.
- [X] 2025-12-26 Center hover popup with width = buffer width - 12 columns.
- [X] 2025-12-26 Strip hover code fences and anchor popup under cursor line.
- [X] 2025-12-26 Preserve hover position on refocus by caching cursor row.
- [X] 2025-12-26 Remove hover custom highlighting (retain border + sizing).
- [X] 2025-12-26 Preload Blink on InsertEnter and force Rust fuzzy binaries on WSL.

## Performance Instrumentation Initiative
- [X] Create `lua/perf/collector.lua` with fixed-capacity SoA buffers, batching flush, and serializer.
- [X] Implement `lua/perf/init.lua` to expose `:PerfTraceEnable`, `:PerfTraceDisable`, `:PerfTraceFlush`, and honor `NVIM_PERF_TRACE`.
- [X] Wrap lazy.nvim plugin callbacks to log init/config/build timings without altering behavior.
- [X] Trace Lua module loads via `package.searchers` interception and persist summaries.
- [X] Provide helper wrappers for autocmd/keymap/user-command registration that capture execution stats.
- [X] Sample background state (GC, buffers, Treesitter, LSP) on low-frequency timers.
- [X] Build `lua/perf/report.lua` to aggregate logs and render `:PerfReport` outputs.
- [X] Ship documentation + workflow notes (`lua/perf/todos.md`) and maintain a perf changelog.
- [ ] Add automated tests for collectors and wrappers; run controlled benchmarking sessions to validate output.

## Legacy Tasks
- [X] Move standalone script files to `./lua/scripts/...` and give them new names.
- [ ] Why did we decide to move `pretty_line_numbers()` out of `scripts.lua` and into a dedicated file?
- [ ] Shoulg git ignores always be in `/mnt/c/Users/Christopher/AppData/Local/nvim/.git/info/exclude`?
- [ ] After moving `pretty_line_numbers()` around I see various bugs related to the numberline. I.e. occasionally it'll appear on one side of the screen from lines 0-20 or so, then the right side of the screen, from the top to the bottom of the screen, where the first few lines are 0, 0, 0, 08, 09, 10... Weird. This fixes itself after scrolling. Mostly happens in pop ups and new tabs opened with e.g. LspInfo. Don't change anything yet, but
- [ ] See the following error when trying to open Oil when Telescope is open.
  ```
  Error executing Lua callback: ...l/nvim-data/lazy/lazy.nvim/lua/lazy/core/handler/cmd.lua:48: Vim:Error executing Lua callback: ...r/AppData/Local/nvim-data/lazy/oil.nvim/lua/oil/init.lua:383: Vim:E37: No write since last change (add ! to override)                                                                                     stack traceback:                                                                                                       [C]: in function 'edit'                                                                                        ...r/AppData/Local/nvim-data/lazy/oil.nvim/lua/oil/init.lua:383: in function <...r/AppData/Local/nvim-data/lazy/oil.nvim/lua/oil/init.lua:374>                                                                                ...r/AppData/Local/nvim-data/lazy/oil.nvim/lua/oil/init.lua:1180: in function <...r/AppData/Local/nvim-data/lazy/oil.nvim/lua/oil/init.lua:1126>                                                                              [C]: in function 'cmd'                                                                                         ...l/nvim-data/lazy/lazy.nvim/lua/lazy/core/handler/cmd.lua:48: in function <...l/nvim-data/lazy/lazy.nvim/lua/lazy/core/handler/cmd.lua:16>                                                                          stack traceback:                                                                                                       [C]: in function 'cmd'                                                                                         ...l/nvim-data/lazy/lazy.nvim/lua/lazy/core/handler/cmd.lua:48: in function <...l/nvim-data/lazy/lazy.nvim/lua/lazy/core/handler/cmd.lua:16>                                                                          Press ENTER or type command to continue
  ```

## Code TODO Backlog (2025-11-11)

### ./init.lua
- [ ] ./init.lua:29 Document the WSL detection helper that exports `vim.g.is_wsl` and note consumers that rely on it.

### ./lua/settings.lua
- [ ] ./lua/settings.lua:26 Sort and organise the option/flag declarations so startup state is deterministic.
- [ ] ./lua/settings.lua:28 Verify that disabling built-in plugins via `vim.g.loaded_*` is reliable across Lazy loads.
- [ ] ./lua/settings.lua:44 Evaluate using `XDG_CONFIG_HOME` / `XDG_DATA_HOME` on both Windows paths and WSL.
- [ ] ./lua/settings.lua:46 Consolidate `SHADA_DIRECTORY` ownership so autocmd consumers read from a single source of truth.
- [ ] ./lua/settings.lua:98 Re-test the WSL clipboard caching strategy before re-enabling it.

### ./lua/autocmds.lua
- [ ] ./lua/autocmds.lua:98 Decide on the WSL clipboard sync workflow (focus gained/lost) or remove the dormant autocmd block.

### ./lua/keybindings.lua
- [ ] ./lua/keybindings.lua:88 Restore the default `<C-e>` replace behavior so scroll bindings need no overrides.
- [ ] ./lua/keybindings.lua:129 Detect when the current buffer is a terminal and prepend `<Esc>` so movement keys work reliably.
- [ ] ./lua/keybindings.lua:144 Confirm why `<leader>e` maps to `'</<C-X><C-O>'` and whether it should remain tied to Oil/terminal hacks.
- [ ] ./lua/keybindings.lua:225 Work out Blink's custom keybinding requirements instead of relying on `vim.keymap.set` defaults.
    - [ ] ./lua/keybindings.lua:226 Cross-reference `./lua/plugins/lazy-blink-cmp.lua` so the Blink mappings align with the plugin config.

### ./lua/scripts.lua
- [ ] ./lua/scripts.lua:8 Remove the global `_G.M` exposure or justify it with measured startup costs.
- [ ] ./lua/scripts.lua:16 Audit the eager module calls (e.g. `scripts.c_return_types`, `scripts.custom_diagnostics`) and document why they run on load.
- [ ] ./lua/scripts.lua:68 Make the custom numberline flow operate inside help buffers / other read-only windows.
- [ ] ./lua/scripts.lua:69 Package `pretty_line_numbers` as a plugin-friendly setup function for Lazy and other managers.
    - [ ] ./lua/scripts.lua:71 Review Lazy documentation / peer plugins for best practices before exporting the setup entry point.
    - [ ] ./lua/scripts.lua:72 Add toggleable options (colours, active-line highlight, padding, etc.) to the numberline setup.
- [ ] ./lua/scripts.lua:452 Determine whether the commented `_G.ReloadConfig` helper still provides value.
    - [ ] ./lua/scripts.lua:457 Ensure any reload flow properly purges modules under `lua/` instead of leaving stale bytecode.
- [ ] ./lua/scripts.lua:473 Verify that the legacy plugin sourcing helpers actually work or remove them.
- [ ] ./lua/scripts.lua:593 Track non-file buffers (completion popups, scratch, etc.) so custom buffer listings stay accurate.

### ./lua/scripts/visrep.lua
- [X] 2025-11-23 Fix UTF-8 visual selections in Visrep so multibyte characters are replaced wholly (no `<86><92>` / `<b6>` artifacts).
- [X] 2025-11-24 Live preview now rebuilds affected lines so text shifts while typing replacements instead of being overdrawn.
- [X] 2026-01-05 Extend prompt literal truncation to 77 chars with ellipsis.
- [X] 2026-01-05 Add Tree-sitter scoped mode toggle/expand/contract with out-of-scope dimming.
- [ ] ./lua/scripts/visrep.lua:12 Ensure the `[N/N]` navigator starts at the original match rather than the literal first.
- [ ] ./lua/scripts/visrep.lua:13 Provide standard plugin configuration hooks for Visrep.
- [ ] ./lua/scripts/visrep.lua:14 Add `vim.g.visrep_default_mode = 'boundary'|'anywhere'` to control the initial boundary mode.
- [ ] ./lua/scripts/visrep.lua:15 Expose preview scope knobs such as `vim.g.visrep_preview` and `vim.g.visrep_preview_margin`.
- [ ] ./lua/scripts/visrep.lua:16 Make Visrep highlight groups (e.g. `VisrepText`) configurable for theming.
- [ ] ./lua/scripts/visrep.lua:17 Debounce rerenders (~10–20ms) so rapid typing doesn’t thrash the overlay.
- [ ] ./lua/scripts/visrep.lua:18 Implement an async match index for very large files (>100k lines).
- [ ] ./lua/scripts/visrep.lua:19 Respect Unicode / `iskeyword` boundaries instead of ASCII-only parsing.
- [ ] ./lua/scripts/visrep.lua:20 Extend live preview to multi-line selections.
- [ ] ./lua/scripts/visrep.lua:21 Diff previous/next visible ranges so viewport updates are incremental.
- [ ] ./lua/scripts/visrep.lua:22 Offer case-sensitivity toggles (smartcase / explicit modes) per run.
- [~] 2026-01-05 Drafted Visrep TODOs brainstorming doc at docs/plans/brainstorming.md (scope + prompt length).

### ./lua/scripts/c_return_types.lua
- [ ] ./lua/scripts/c_return_types.lua:484 Provide a lightweight toggle/disable path so large files aren’t penalized.

### ./lua/scripts/custom_diagnostics.lua
- [ ] ./lua/scripts/custom_diagnostics.lua:7 Suppress diagnostics banners when a buffer is dirty to avoid stale warnings.
- [ ] ./lua/scripts/custom_diagnostics.lua:8 Ensure diagnostics are fully cleared after errors disappear instead of sticking at EOF.
- [ ] ./lua/scripts/custom_diagnostics.lua:10 Rename the `custom_diagnostics` namespace to follow conventions.

### ./lua/scripts/wrappin.lua
- [!] ./lua/scripts/wrappin.lua:11 Wrappin strips Markdown header prefixes; strengthen prefix handling so headings survive wrapping.
- [ ] ./lua/scripts/wrappin.lua:16 Support partially wrapped selections by only reflowing overflowing lines.
- [ ] ./lua/scripts/wrappin.lua:20 Store the original layout (scratchpad) so users can revert after edits.

### ./lua/plugins/lazy-blink-cmp.lua
- [ ] ./lua/plugins/lazy-blink-cmp.lua:3 Configure Blink sources (buffers, docs, etc.) instead of relying on defaults.

### ./lua/plugins/lazy-treesitter-odin.lua
- [ ] ./lua/plugins/lazy-treesitter-odin.lua:3 Add a Wrappin option that leaves filepaths / unbroken strings unwrapped.

### ./lua/plugins/lazy-oil.lua
- [ ] ./lua/plugins/lazy-oil.lua:46 Investigate why `get_oil_winbar()` never returns a directory and repair the winbar hook.

### ./lua/plugins/lazy-mini-align.lua
- [ ] ./lua/plugins/lazy-mini-align.lua:32 Provide custom alignment presets instead of using the default setup.

### ./lua/plugins/lazy-nvim-surround.lua
- [ ] ./lua/plugins/lazy-nvim-surround.lua:14 Add cycling keymaps (e.g. repeated `<C-e>`) for selecting surround pairs.

### ./lua/plug.bak
- [ ] ./lua/plug.bak:157 Fix the Trouble signs padding so diagnostics align.
- [ ] ./lua/plug.bak:193 Add mini.align custom alignment rules in the legacy plug config too.
- [ ] ./lua/plug.bak:471 Document how the `luasnip` expand function integrates with cmp.
- [ ] ./lua/plug.bak:531 Document the `lua_ls` setup rationale (custom settings vs `lsp-zero`).
- [ ] ./lua/plug.bak:598 Figure out why the old NvimTree workflow made buffers hard to track / statusline flash.
- [ ] ./lua/plug.bak:604 Fix buffer padding glitches in the NvimTree graveyard config.

## Notes

- [~] SourceKit-LSP (Swift) is provided by the Apple toolchain and is not packaged by mason-lspconfig; configure it manually without adding it to `ensure_installed`.
- [~] LSP capabilities now probe both `blink.cmp` and `blink-cmp` module names for completion integration.
- [~] SourceKit LSP now registered via `vim.lsp.config('sourcekit', …)` with swift.nvim providing path detection and buffer lifecycle hooks.
- [~] 2025-11-10: Guard `guicursor` inside tmux whenever `client_termfeatures` reports SIXEL and the server predates tmux#4488 (override via `NVIM_TMUX_SIXEL_WORKAROUND`).
- [~] 2025-12-04: tmux `extended-keys on` + `terminal-features:extkeys` to preserve Ctrl+Enter (and other CSI-u combos) for Neovim.
- [~] 2025-12-04: Copilot keeps `<C-CR>` primary accept and adds `<C-\\>` as tmux-safe fallback; Blink retains its `<C-CR>` completion binding.
- [~] 2025-12-04: Added tmux `terminal-features *,extkeys` + server/global `extended-keys` to decode Ctrl+Enter sequences.
