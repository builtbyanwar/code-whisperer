# Hook smoke test — v2.0 evidence log

This file records the testing that gated the v2.0 release and documents the
two features that were piloted and then cut.

## Part A — UserPromptSubmit Haiku classifier (cut)

### What was tested

A `UserPromptSubmit` hook that called Claude Haiku on every prompt and
optionally injected a feature tip via `additionalContext`. The prompt was
designed to return `{}` for anything conversational/ambiguous and only
emit a tip for concrete technical goals with a clear native feature.

### Gate criteria

- **Cat 1: conversational prompts** must pass through silently.
- **Cat 2: clear technical goals** may inject a tip; silent is also fine.
- **Cat 3: ambiguous prompts** must pass through silently.

### Results

Twelve prompts run across Cat 1–3:

| Category | Prompts | Tips fired | Blocks |
|----------|---------|-----------:|-------:|
| Cat 1 (conversational) | 4 | 0 | 0 |
| Cat 2 (technical) | 4 | 0 | 0 |
| Cat 3 (ambiguous) | 4 | 0 | 2 |

The two blocks were on variants of "could it be because I have skills like
supermemory installed so they are firing up?" — a conversational follow-up
with no technical content. First attempt and retry both blocked with
"Operation stopped by hook" banners explaining the reasoning. The hook was
explicitly told never to block; it blocked anyway. That's the unavoidable
false-block rate of a per-prompt LLM gate on the hot path.

Cat 2 was telling in the other direction: zero tips across four prompts
that each mapped cleanly to a documented native feature (`/batch`,
`/loop`, Explore subagent, `/schedule`). The base model and installed
skills already routed to the relevant skill on their own.

### Verdict

Under-fires where it should help, over-fires where it must not. Removed
from installer, live settings, and the skill's scripts directory.

## Part B — PostToolUse pattern watcher

Deterministic bash. Tests [pattern-watcher.sh](../scripts/pattern-watcher.sh).

### `parallel-tasks` nudge (cut)

Originally intended to fire when Claude dispatched 3+ `Task`/`Agent` calls
sequentially. Two problems surfaced in testing:

1. The watcher originally only matched `Task|` in tool logs, but current
   Claude Code reports the tool as `Agent`. Fixed by matching both.
2. Even after the tool-name fix, the pattern turned out not to be
   reliably detectable. Real sessions showed ~15–25 intermediate tool
   calls (Bash, Read, Grep, Glob) between Agent dispatches as Claude
   processed one Agent's output and set up the next. A `tail -n 40`
   window would be required to catch three Agents in a typical
   session — which makes "sequential" meaningless and would fire on
   any multi-Agent session regardless of whether parallelism was
   appropriate.

Evidence: session log showed Agent dispatches at positions 11, 35, 50 out
of 50 total tool calls. No reasonable tail window catches all three.

Dropped. `superpowers:dispatching-parallel-agents` already covers this
use case via its skill description.

### `batch-bash` nudge (kept)

Fires when the same `first-word second-word` Bash signature appears 4+
times in the last 8 Bash calls.

**Smoke test (Cursor + Claude Code extension):** ran four `git log`
commands with different flags (`main`, `--since`, `--merges`,
`--author`). Watcher fired correctly — confirmed via marker file
`nudged-batch-bash` in the session state directory, and confirmed via
direct CLI invocation of the watcher script emitting the expected JSON
structure. Claude acknowledged the tip in its reply ("Re: the hook tip —
`/batch` wouldn't fit well here since each `git log` had different flags…").

**Rendering caveat:** the `systemMessage` banner did not render as a
visible distinct line in the Cursor IDE surface. The `additionalContext`
part reached Claude successfully and Claude surfaced the tip in its
reply. Terminal `claude` CLI rendering was not tested in this smoke run.
See README for the "Where you'll see the tip" note.

### `explore-subagent` nudge (kept)

Fires when 8+ `Read`/`Grep` calls appear in the last 12 tool uses.

**Smoke test:** confirmed firing in the same Cursor session (marker file
`nudged-explore-subagent` present). Not independently verified by text
in Claude's reply, but the marker file is sufficient evidence that the
threshold tripped and the hook emitted output.

### Nudge output format

Both kept nudges emit JSON of this shape:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "💡 code-whisperer: <message>"
  },
  "systemMessage": "💡 code-whisperer: <message>"
}
```

Belt-and-suspenders: `additionalContext` tells Claude, `systemMessage`
tells the user (where the UI surfaces it).

## Sign-off

- UserPromptSubmit classifier: **CUT** based on Cat 1–3 evidence above.
- parallel-tasks nudge: **CUT** based on window-size evidence above.
- batch-bash nudge: **PASS** (marker file + direct CLI verification +
  Claude acknowledgment in reply).
- explore-subagent nudge: **PASS** (marker file).

Tester: Anwar BinUmer
Date: 2026-04-13
Surface tested: Cursor IDE with Claude Code extension
