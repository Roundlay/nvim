# Visrep TODOs Brainstorming (2026-01-05)

## Scope

This design document covers only the two TODOs in `/mnt/c/Users/Christopher/AppData/Local/nvim/lua/scripts/visrep.lua`:
- Increase the prompt literal truncation length (single-line cmdline UI stays).
- Add scoped replacement mode with expansion/contracting around the selection.

## Decisions

- Prompt literal display: show up to 77 characters; if longer, truncate and append a literal ellipsis character.
- Scope backend: Tree-sitter named nodes only, starting at the smallest named node that fully contains the selection (LCA when spanning nodes).
- Scope toggles/controls: `<S-Tab>` toggles scoped mode, `<C-k>` expands, `<C-j>` contracts; no wrap at bounds.
- Scope anchoring: scope is anchored to the original selection; `<C-n>/<C-p>` only navigate within current scope and only when selection is a valid match.
- Scope filtering: matches must be fully inside scope (no overlap-only matches).
- Scope availability: if Tree-sitter is unavailable or no suitable node exists, scoped mode is disabled and a brief prompt message is shown.
- Dimming: dim everything outside the active scope, across the entire buffer, with full precision including boundary-line segments; use `VisrepScopeDim` linked to `NonText`.
- Counts/indexing: counts reflect only valid matches; selection invalid + matches exist -> `[0/N]` and no nav; none exist -> `[0/0]`.
- Multi-line selections: no scoped mode; keep current simple prompt path.
- Mode interaction: scoped toggle preserves boundary/anywhere mode; boundary/anywhere toggle preserves scoped state and level.

## Design Presentation (Verbatim)

**Overview & Objectives (Section 1)**
We will adjust Visrep’s single‑line interactive prompt to show longer selections (up to 77 characters) before truncating with a literal ellipsis character, preserving the current single‑line cmdline UI while avoiding premature loss of context. In parallel, we will add a “scoped mode” that narrows match discovery and replacement to a Tree‑sitter‑defined range rooted at the smallest named node that fully contains the selection. Scoped mode is a toggle layered on top of the existing boundary/anywhere modes, yielding Anywhere (Scoped) and Boundary (Scoped) without altering the boundary semantics themselves.

User input behavior will remain consistent: `<Tab>` toggles boundary/anywhere; `<S‑Tab>` toggles scoped mode on/off; `<C‑k>` expands scope upward to parent named nodes; `<C‑j>` contracts back toward the smallest named node; scope expansion stops at the top/bottom without wrapping. Scoped mode is anchored to the original selection and does not move when navigating matches. Matches are counted only if valid under the current mode/scope. If the selection is a valid match, the current index reflects its position in buffer order. If the selection is invalid but other valid matches exist, the UI shows `[0/N]`, keeps the cursor on the selection, and disables `<C‑n>/<C‑p>` navigation until the mode/scope changes. If no valid matches exist, the UI shows `[0/0]`. When scoped mode is unavailable (no Tree‑sitter parser or suitable node), it is disabled and a brief prompt message is shown. Visual feedback for scope is provided by dimming all text outside the active scope with a `VisrepScopeDim` highlight linked to `NonText`, applied across the entire buffer with full‑precision (including boundary‑line segments).

**Architecture & Components (Section 2)**  
We’ll extend the existing single‑line interactive loop with a small “scope state” alongside the current mode state. Conceptually: selection → literal pattern → global match index (already computed) → **optional scope filter** → active match list + nav list → preview render + prompt. Scope state consists of: `scoped_enabled` (toggle), `scope_nodes` (stack/list of named Tree‑sitter nodes from smallest to root), `scope_idx` (current level), and a cached `scope_range` (start row/col, end row/col exclusive). When scoped mode is off, matching uses the full buffer as today. When scoped mode is on, matching is limited to occurrences fully inside the active `scope_range`, preserving boundary/anywhere logic unchanged.

Tree‑sitter integration will be read‑only: on entering scoped mode, we resolve the smallest **named** node that fully contains the selection (lowest common ancestor if selection spans nodes), then walk parent named nodes to the root, capturing their ranges in order. `<C‑k>` increments `scope_idx`, `<C‑j>` decrements, and we do nothing at bounds. Toggling scoped mode off retains the computed `scope_nodes` and `scope_idx` in memory; toggling back on restores the previous scope level. If no Tree‑sitter parser or node is available, scoped mode does not activate and a brief prompt message is emitted; the flow continues unscoped.

For visual scope feedback, we’ll use a dedicated dimming overlay across the entire buffer. Outside‑scope text is dimmed with a new highlight group `VisrepScopeDim` linked to `NonText`. Dimming is precise: for boundary lines, only the outside segments are dimmed. This is layered on top of the existing preview overlay, without altering the prompt UI or cursor restoration behavior.

**Key Workflows & Interactions (Section 3)**  
Entry flow (single‑line selection): we compute the literal pattern, build the match index as today, then initialize prompt state. Prompt rendering uses the longer 77‑char truncation rule for the selected literal. The current mode (boundary/anywhere) is preserved from existing logic; scoped mode starts off by default. On each input key:  
- `<Tab>` toggles boundary/anywhere; preserves scoped mode and scope level.  
- `<S‑Tab>` toggles scoped mode on/off; when enabling, we resolve Tree‑sitter scope nodes and compute the active range; on disable, we keep cached scope state for later restore.  
- `<C‑k>/<C‑j>` expand/contract scope when scoped mode is active; no effect at bounds.  
- `<C‑n>/<C‑p>` move between valid matches **only when the current selection is a valid match**, and only within the current mode/scope. If the selection is invalid, these keys do nothing.  
- All other keys behave as today (text input, backspace, enter, escape).

Match counting and indexing are recomputed on every rerender:  
- If the selection is a valid match under the current mode/scope, we pick its buffer‑order index as the current position.  
- If invalid but other valid matches exist, we show `[0/N]` and keep the cursor on the selection.  
- If no valid matches exist, show `[0/0]`.  
- On rerender, the preview and prompt reflect the scoped filter (if active).  

The visual scope dimming is updated alongside preview overlay: the whole buffer is dimmed outside the active scope range with full precision (including boundary‑line segments). This dimming layer is scoped to the same namespace lifecycle as the preview overlay so that escape or enter clears all overlays cleanly.

**Data Structures, Algorithms & Interfaces (Section 4)**  
We’ll keep the existing literal match index (`by_line_any`, `by_line_bnd`, and their nav lists) as the base “full‑buffer” dataset, since it already provides fast per‑line match ranges and a linear nav list. Scoped mode will introduce a lightweight filtering stage rather than re‑indexing: given a `scope_range` (start row/col, end row/col exclusive), we derive `active_by_line` and `nav_targets` by retaining only matches whose spans are **fully inside** that range. This preserves the current data flow and keeps changes localized. Filtering can be done per rerender by scanning the existing nav list (linear pass) and producing a filtered nav list plus a per‑line list of matches for preview. This avoids recomputing string finds and keeps the hot path narrow.

Tree‑sitter scope state will be represented as a small array of `nodes` with their precomputed ranges (start row/col, end row/col). We’ll store them ordered from smallest‑to‑largest (child→root). `scope_idx` selects the active range. On scope toggle/expand/contract, we simply update `scope_idx` and recompute the filtered match lists.

Prompt text will be assembled from: `[idx/total]`, selection literal (truncated to 77 with ellipsis), current mode label, and a `[scoped]` tag when scoped is active. The count/idx logic uses the filtered nav list: if the selection tuple exists in it, current index becomes that entry’s position; if not, current index is `0`. This maintains a strict “valid matches only” count.

Overlay rendering is a two‑stage projection: (1) the existing per‑line replacement preview overlay; (2) a dimming overlay outside the scope, using the same namespace. For precise dimming, we’ll represent dim segments as per‑line ranges computed from the `scope_range` and apply extmarks or virt‑text overlays accordingly. The overall interface (user keys, prompt UI, replacement command) stays unchanged.

**Edge Cases & Constraints (Section 5)**  
- **Tree‑sitter unavailable:** If no parser or no named node contains the selection, scoped mode stays off and we emit a brief prompt message; the rest of the flow continues unscoped.  
- **Selection invalid under mode/scope:** Counts reflect only valid matches. If none, `[0/0]`. If others exist, `[0/N]` while keeping the cursor on the selection; `<C‑n>/<C‑p>` do nothing in this state.  
- **Multi‑line selections:** Scoped mode and live preview are **not** enabled; multi‑line continues to use the simple input prompt.  
- **Scope bounds:** `<C‑k>/<C‑j>` stop at smallest/root node (no wrap, no auto‑exit).  
- **Scope inclusion:** Matches must be fully inside the active scope range (no overlap‑only matches).  
- **Dimming precision:** Outside‑scope dimming is applied to the whole buffer with boundary‑line segments precisely dimmed, ensuring clarity even when scope starts/ends mid‑line.  
- **Prompt length:** Literal display truncates only after 77 chars, keeping single‑line UI intact.

## Open Questions

None at this time.
