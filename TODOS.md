# TODOs

- [ ] Analyse perf. log output!
- [X] 2025-11-06 Fix lualine truncated filepath compression to operate on Unix separators.

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

## Notes

- [~] SourceKit-LSP (Swift) is provided by the Apple toolchain and is not packaged by mason-lspconfig; configure it manually without adding it to `ensure_installed`.
