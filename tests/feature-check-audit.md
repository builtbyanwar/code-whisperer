# /feature-check audit smoke test — v2.1 evidence log

Manual verification of the `/feature-check` pipeline before tagging v2.1.

## What this tests

The v2.1 release adds `scripts/session-audit.sh` — a Haiku-powered
session auditor that reads the current session's tool log, cross-
references against `references/native-features.md`, and returns a
markdown report of features that would have materially changed how the
user worked.

The pipeline:

1. `/feature-check` in SKILL.md tells Claude to run
   `update-knowledge-base.sh` silently (refresh), then
   `session-audit.sh` (audit), then relay the output verbatim.
2. `session-audit.sh` resolves session_id, compacts the tool log,
   builds a three-section input block, and invokes
   `claude -p --model claude-haiku-4-5-20251001 --system-prompt-file audit-prompt.txt`.
3. Haiku returns either a structured markdown report (≤5 features) or
   the exact sentence "No notable feature gaps in this session..." if
   the gap analysis comes up empty.

## Test cases

### Case 1 — Rich session (141 tool calls)

**Session:** `0b43ea58-3cce-4f36-92cf-820b03a8fb65` — earlier session
with heavy Bash + Grep + Read activity and 3 Agent dispatches.

**Invocation:**
```bash
bash scripts/session-audit.sh 0b43ea58-3cce-4f36-92cf-820b03a8fb65
```

**Observed output:**

```markdown
### Explore subagent

**What:** Specialized subagent for fast, read-only codebase exploration
using pattern matching and keyword search.

**Relevance to this session:** You performed 22 file operations
(grep -r ×5, cat ×8, find ×2, head ×3, ls ×3, grep -A5 ×1) and 2 Read
tool calls to understand code structure. The Explore subagent is
designed to consolidate this entire workflow into a single invocation,
providing built-in pattern matching, keyword discovery across files,
and architecture analysis automatically.

**How to invoke:** Agent tool with `subagent_type: "Explore"` — specify
a search task like "find all API endpoints", "search for authentication
usage", or "explain the module architecture".

**Source:** https://code.claude.com/docs/en/subagents
```

**Pass criteria met:**

- Output is markdown, ≤5 features ✅ (returned 1 feature, correctly
  declining to pad)
- Concrete evidence from the tool log ✅ ("22 file operations", counts
  by command type)
- Registry-bound — feature exists in native-features.md ✅
- Source URL present ✅
- No preamble, no postscript ✅

### Case 2 — Light session (4 tool calls)

**Session:** `dafdd748-d112-4b39-b478-e998cfe7bfa0` — minimal activity.

**Invocation:**
```bash
bash scripts/session-audit.sh dafdd748-d112-4b39-b478-e998cfe7bfa0
```

**Observed output:**

```
No notable feature gaps in this session. Either the session was light
on activity, or the user is already reaching for the right native
features.
```

**Pass criteria met:**

- Exact sentence from the audit prompt's empty-gap template ✅
- No invented features ✅
- No padding or apology ✅

### Case 3 — Auto-detect (no session_id argument)

**Invocation:**
```bash
bash scripts/session-audit.sh
```

**Observed:** Picked up the current session (most-recently-modified
state dir), returned the empty-gap sentence correctly because the
current session was light on activity.

**Pass criteria met:**

- Auto-detection via `ls -t | head -n 1` works ✅
- Downstream behaviour identical to explicit session_id ✅

## Design notes worth recording

### `--bare` was removed from the claude invocation

Initial implementation used `claude -p --bare --system-prompt-file ...`.
The `--bare` flag produced `Not logged in · Please run /login` because
it skips the auth keychain read, and a subprocess without auth cannot
reach the model even though the parent Claude Code session is logged in.

Fix: drop `--bare`. The `--system-prompt-file` flag alone gives enough
control — testing showed Haiku respects the audit prompt's strict rules
(registry-bound, no padding, exact empty-gap sentence when applicable).

Trade-off: without `--bare`, the subprocess inherits the user's CLAUDE.md,
memory system, and any other Claude Code config that applies to `claude -p`
invocations. Observed behavior is clean — no evidence of pollution from
ambient context. If future tuning shows leakage, revisit with
`--append-system-prompt-file` or by running through the Anthropic SDK
directly.

### Failure modes are soft

- `session-audit.sh` exits 0 on Haiku failure (auth, rate limit, network),
  printing a short warning to stdout rather than raising an error.
  Rationale: `/feature-check` is an optional audit command; a transient
  Haiku outage shouldn't break the user's workflow.
- The script only exits non-zero on hard failures: missing files
  (audit-prompt, native-features, local-features) or missing `claude`
  CLI. These are configuration errors the user needs to know about.

## Sign-off

- Case 1 (rich session): **PASS**
- Case 2 (light session): **PASS**
- Case 3 (auto-detect): **PASS**

Tester: Anwar BinUmer
Date: 2026-04-13
Surface tested: Cursor IDE with Claude Code extension
Model: claude-haiku-4-5-20251001
