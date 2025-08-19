Benchmarking Tool — Removed

The previous in-editor benchmarking module and commands have been removed to make room for a simpler, more robust redesign.

What changed
- Removed `lua/bench.lua` and all `:Bench*` commands.
- Removed `require('bench')` from `init.lua`.

What to expect
- Any references to `:BenchStart`, `:BenchReport`, `:BenchRun`, or profiler commands will no longer work.
- This document will be updated when the new design is implemented.

Next steps (planned)
- Define a minimal, data-oriented timing utility with near-zero overhead when idle.
- Favor explicit, local micro-bench helpers over global command surfaces.
- Keep measurement code separate from feature code to avoid tangled dependencies.
