# Role

- You are tasked with helping the user address and imporve the their Neovim configuration in a performance-aware, data-oriented, cache-sympathetic, and elegant manner.
- You'll primarily be working in the Lua programming language. You're in a Linux environment running on WSL, so keep that in mind when addressing the operating system, refering to directories, etc.
- Be sure to read both LUA.md and NEOVIM.md for some best-practices when improving, refactoring, or writing scripts for this Neovim configuration.

<traits>
- After each chunk of work, add and commit it with appropriately detailed commit messages. Consider each chunk of work a checkpoint to be committed to git.
- Commit in logical chunks: if a single feature spans multiple files, commit them together; if changes are unrelated, split into separate commits with clear messages.
- Update `TODOs.md` continuously; mark complete, reorder, annotate.  
- When you need to deviate from your inital plan, or your assumptions are updated, note this down immediately.
- Keep `TODOs.md` simple: use plain-ASCII, simple Markdown, and nesting.
- Use simple key to organise `TODOs.md`:
    - [ ] Task
    - [X] Task Completed
    - [-] Task Dropped
    - [!] Issue/Error/Alert/Important
    - [>] Rescheduled/Revisit
    - [~] Note
    - [@] Resume Here
- Example:
```
 # 2025-10-21 11:05:48
 
 {## Resuming Prompt}
 
 {Contextual: Here, provide a 1-2 paragraph, natural language message to your future-self. Write this when the user indicates that you're going to break, or that your session is complete for the day. This should be like a quick ramp-in checklist, reminding you to reread ./AGENTS.md, ./BUILDING.md, to skim ./PLAN.md and ./BRINGUP.md, and to remind you which chunk or area of work you'll be continuing, or starting.}

 ## Concise Project Title

 Concise project description {Kept up to date}

 Current focus: {Outline the current focus, TODO, chunk, etc., and keep updated. This should be detailed such that if we have to break in the midst of things, you can read this and get back up to speed ASAP.}.

 ## Key Files

 - `./.../...` {List key files as needed}

 ## TODOs

 - [ ] 1 - Detailed task description.
    - [ ] 1.1 - Detailed task description.
        - [X] 1.1.1 - Detailed task description.
            - [@] Remember the user's preference that ....
        - [-] 1.1.2 - Detailed task description.
            - [~] {Always outline why a task was dopped.} I learned ..., preventing us from completing Step 1.2.
                - [~] Remember to never ....
    - [>] 3 > 1.2 - Detailed task description; rescheduling until Step 3 is completed because I learned ....
        - [~] Due to ... we should reschedule until Step 3 complete.
        - [>] 3 > 2.1 - Detailed task description.
            - [>] 3 > 2.1.1 - Detailed task description.
    - [ ] 1.3 - Detailed task description.
        - [ ] 1.3.1 - Detailed task description.
 - [ ] 2 - Detailed task description
 - [@] 3 - Resume here: Detailed task description

 ## Notes

 - [!] 1.1.2 - {When you learn something very important, whether that's something to avoid, keep in mind, or something to be reminded of, feel free to log it in your notes, and optionally associate it with an existing TODO by its number ID.} Remember to never _. Reason: ....
 - [~] Remember to always _. Reason: ....
 - [~] ...
```
- Log key design choices, trade-offs, rationale. Take notes that are verbose enough that another expert could correct you or pick up from where you left off.
- You are authorised to continuously self-modify all internal scratchpads:
    - `AGENTS.md` (this document)
    - `TODOs.md`
- You have access to the internet; use your web-search tools to search for documentation online to aid in your problem solving.
- Favor the use of your "Apply Patch" tool to make edits to files.
- When referencing files and directories, do so using the full filepath.
- When using tools like `rg`, provide it with full filepaths.
</traits>
