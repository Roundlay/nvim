Neovim API performance practices—what to use, what to avoid, and how to structure plugins (Lua/LSP/Tree‑sitter/diagnostics/UI) to minimize latency, allocations, redraws, and RPC overhead.

* Prefer **Lua `vim.api`** over `vim.fn`/`vim.cmd` in hot paths to avoid the Vimscript bridge’s marshalling overhead.
* Treat **“fast” contexts** carefully: if `vim.in_fast_event()` is true, don’t mutate buffers/windows—wrap work with `vim.schedule()`/`vim.schedule_wrap()` (or `vim.defer_fn`).
* **Batch edits**: compute text in Lua, then apply once with `nvim_buf_set_lines`/`nvim_buf_set_text` (avoid many tiny edits).
* **Reduce RPC round‑trips** from remote clients: run code inside Nvim with `nvim_exec_lua()` (note `nvim_call_atomic()` is deprecated).
* When you need to **read many lines**, use one `nvim_buf_get_lines` slice—not per‑line calls.
* **Clear decorations** in one shot with `nvim_buf_clear_namespace()` rather than deleting extmarks one‑by‑one.
* **Decoration providers** (`nvim_set_decoration_provider`): keep callbacks O(1), bail early for irrelevant buffers, and do not change state—schedule mutations to the main loop.
* Use **ephemeral extmarks** (`ephemeral=true`) from decoration providers so marks aren’t persisted between redraws.
* Prefer **async processes** with `vim.system()` (libuv) over blocking `vim.fn.system()`; await via `:wait()` only when necessary.
* For background work, use **`vim.uv` timers** to throttle/debounce frequent events (e.g., `CursorMoved`) and schedule UI updates.
* **Don’t call API functions** inside tight redraw loops unless necessary (e.g., inside `on_line` of a decoration provider); precompute/capture data instead.
* **Avoid `:redraw!`** in loops; let Nvim coalesce screen updates or perform a single redraw at the end.
* **Use namespaces** for highlights/signs and **adjust by namespace** rather than touching global groups every time.
* Prefer **`vim.keymap.set`** (Lua callbacks) set once at startup; avoid repeatedly redefining maps at runtime.
* **Limit autocommands**: scope (`buffer`/`pattern`), group them, and debounce heavy handlers.
* **Subscribe to buffer updates** with `nvim_buf_attach()` and react incrementally instead of rescanning the buffer on every keystroke.
* Remember **textlock** in buffer‑update callbacks—query is fine, but **mutations must be scheduled**.
* Prefer **Tree‑sitter reused state**: keep a parser per buffer and **reuse compiled queries** (`vim.treesitter.query.parse`) instead of re‑parsing on each event.
* **Avoid synchronous waits** (`vim.wait`) in plugin code; prefer callbacks/coroutines scheduled via `vim.schedule()` or libuv.
* **Minimize virtual text churn**: fewer chunks, shorter strings, and only update when necessary (diagnostics, inlay hints, etc.).
* Tune **diagnostic rendering**: set `vim.diagnostic.config({update_in_insert=false, …})`, use signs selectively, and throttle sources.
* Prefer **async LSP** (`vim.lsp.buf_request`/notifications) over sync requests; avoid blocking on `buf_request_sync`.
* For options, **read once, write once**; use `vim.o`/`vim.bo`/`vim.wo`/`vim.opt` and **the new option APIs** (`nvim_get_option_value`/`nvim_set_option_value`) instead of deprecated ones.
* **Cache module lookups** (`local api = vim.api`, `local fn = vim.fn`) and **enable the bytecode loader** (`vim.loader.enable()`) to speed `require`.
* **Avoid `vim.cmd('normal …')`** in hot paths—prefer direct APIs (cursor, marks, motions).
* For **bulk highlighting**, prefer `nvim_set_hl_ns`/`nvim_set_hl` once (e.g., on `ColorScheme`) instead of per‑insert updates.
* **Use windows/buffers methods** that operate by handle (`nvim_win_set_config`, `nvim_buf_call`) instead of global state changes.
* **Avoid chatty logs** (e.g., `vim.notify`/`print`) on keystroke‑driven events; gate behind levels or sample intervals.
* **Prefer structured Ex APIs** (`nvim_cmd`, `nvim_exec2`) over building long strings for `vim.cmd` when you must run Ex.
* **Sign/diagnostic cleanup**: clear by range/namespace instead of iterating per item.
* **UI elements** (floats/popup menus): update existing windows/buffers; don’t destroy/recreate per frame.
* **Don’t rely on global highlights** for Tree‑sitter captures; set per‑namespace highlights and set them once.
* **Guard high‑frequency handlers** (e.g., `InsertCharPre`, `TextChangedI`): throttle with `vim.uv.new_timer` or coalesce with `vim.defer_fn`.
* When driving Nvim from **external tools**, queue **notifications** where possible and avoid request/response ping‑pong for non‑critical updates.
* **Use `vim.api.nvim_buf_set_mark`/extmarks** for tracking positions through edits rather than recomputing byte/col offsets.
* **Prefer incremental LSP sync** (server‑dependent) and disable expensive LSP features for huge files (semantic tokens, code lenses) as needed.
* **Don’t spawn shells** unnecessarily with `vim.system`; exec the tool directly and stream output handlers to avoid large string builds.
* **Profile before optimizing**: start minimal, add features, and measure (e.g., use LuaJIT profiling and simple timers like `vim.loop.hrtime`).
