What follows is a one‑line‑per‑item checklist of practical Lua performance best practices—covering cache locality, locals vs globals, GC avoidance, and related tips—usable across Lua 5.1–5.4 (with notes for LuaJIT where relevant). Be sure to adhere to these when possible in order to write data-oriented, performance aware Lua code.

```
- Use locals instead of globals in hot code; locals are register‑based and avoid global table lookups.
- Hoist repeated module/field lookups to locals before loops (e.g., local sin = math.sin).
- Prefer numeric for loops over pairs/ipairs in hot paths; iterate contiguous 1..n arrays.
- Keep arrays dense and 1‑indexed to stay in the table’s array part and improve cache locality.
- Maintain an explicit length (n) for arrays and avoid holes; don’t rely on #t for sparse tables.
- Move loop‑invariant computations and constants outside the loop.
- Avoid allocating tables, strings, or closures inside tight loops; allocate once and reuse.
- Reuse temporary tables; clear them in place (nil out keys) to reduce GC churn.
- Build strings by collecting chunks in an array and call table.concat once; avoid .. inside loops.
- Minimize function call overhead in inner loops; inline tiny helpers and avoid higher‑order iterators.
- Avoid metamethods in hot code (__index, __newindex, __pairs, __call); use rawget/rawset when possible.
- Keep table shapes stable; avoid adding/removing lots of keys repeatedly to prevent rehashing.
- Hoist frequently accessed sub‑tables to locals (e.g., local a = t.a; local b = a.b) before loops.
- Keep a given field’s value type consistent (avoid mixing numbers/strings/booleans in the same slot).
- Use dispatch tables (ops[op](...)) instead of long if‑elseif chains when handling many cases.
- Prefer built‑in C library functions (table.sort, string.find/gsub) for heavy lifting over manual Lua loops.
- When sorting numbers, call table.sort without a comparator to avoid per‑comparison Lua calls.
- Avoid tonumber/tostring and parsing in inner loops; convert at the edges.
- On Lua 5.3+, prefer integer arithmetic and integer for‑loops; avoid unnecessary int↔float mixing.
- Cache frequently used fields/upvalues to locals at function entry (e.g., local t = self.t; local n = self.n).
- Avoid pcall/xpcall inside hot loops; catch errors at a higher level.
- Batch I/O (read/write in large chunks) instead of many tiny calls inside loops.
- Keep debug hooks and debug.* off in production; they markedly slow execution (and can disable JITs).
- Reduce allocation first; only then tune the GC (collectgarbage("setpause", P), collectgarbage("setstepmul", M)) for your latency/throughput needs.
- Use object pools for short‑lived records in hotspots and recycle them.
- Use weak‑key or weak‑value caches for memoization so cached entries can be collected.
- Represent hot structured data as parallel arrays (structure‑of‑arrays) rather than arrays of tables to improve locality.
- Flatten lookup chains in tight loops (avoid t.a.b.c[i]); bind intermediate tables to locals.
- Cache loop bounds in locals when they don’t change during the loop (e.g., local n = #t).
- Prefer straight‑line loops with predictable branches; hoist rare branches out of the hot path.
- Avoid coroutine.resume/yield inside tight loops; batch work per resume.
- Prebuild constant patterns/format strings outside loops; avoid string.format in inner loops.
- Measure with realistic data and focus on true hotspots; optimize only what profiling shows is hot.
- If you can choose runtime, test on both Lua 5.4 (new GC, features) and LuaJIT (raw speed) and pick per workload.
- (LuaJIT) Keep hot loops trace‑friendly: avoid yields/pcall/metamethods/C calls inside them; use numeric indexing and stable types.
- (LuaJIT) Use FFI arrays/structs for dense numeric data and avoid per‑iteration cdata allocations.
```
