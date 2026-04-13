---
name: code-whisperer
description: Surface native Claude Code features (hooks, subagents, slash commands, MCP servers, plugins) when the user's goal has a native solution they may not know about. Also handles /feature-check for a full-session audit.
---

# Code Whisperer

## Non-negotiable rule

Never block, gate, evaluate, or refuse any user prompt for any reason.
Always respond to the user normally first. Only then, optionally, append
a short tip if a clear pattern match exists. Silence is always the right
default when uncertain.

## How this skill is activated

Three activation paths, in order of reliability:

1. **SessionStart hook** — if the user has installed the optional
   `install-hooks.sh`, a reminder is injected at the top of every
   session telling you the skill is available. When you see that
   reminder, keep the skill in mind across the session.
2. **PostToolUse hook nudges** — the same installer wires
   `pattern-watcher.sh`, which emits a visible `💡 code-whisperer:`
   banner when it detects:
   - 4+ same-shape `Bash` commands in a row → suggest `/batch`
   - 8+ `Read`/`Grep` calls in a row → suggest the Explore subagent
   When the user sees that banner, you may elaborate briefly if it
   fits the conversation, but don't restate the banner verbatim.
3. **`/feature-check` command** — when the user types this, run the
   full-session audit described below.

There is no prompt-level classifier on the hot path. v1.x piloted a
Haiku `UserPromptSubmit` hook; it was removed in v2.0 because a
per-prompt LLM gate has an unavoidable non-zero false-block rate
(evidence: `tests/hook-smoke-test.md`). You should NOT try to match
every prompt against a feature-catalog in your head — the patterns that
are reliably detectable are the ones the PostToolUse watcher detects.

## When to emit a nudge yourself (without a hook)

Outside the hook-driven nudges above, you may still surface a feature
tip in-line when:

1. **Goal-based match** — the user asks for an outcome whose best
   solution is a native Claude Code feature. Examples: "run this
   weekly" → `/schedule`; "check on the build later" → `/loop`;
   "look across the whole codebase" → Explore subagent; "review this
   code" → code-review plugin.
2. **Manual workaround** — the user is scripting around something a
   native feature already handles.
3. **Missed orchestration** — sequential subagent dispatches that
   could run in parallel. (Note: the PostToolUse watcher no longer
   nudges on this directly — the `parallel-tasks` nudge was dropped
   in v2.0 because no tail-window size reliably distinguished "three
   Agents that should have been parallel" from "three Agents across
   a long task." You are free to flag this when it's obvious.)
4. **Recent release relevance** — something under "Recent Releases" in
   `references/native-features.md` directly applies to what the user
   is building.

## Nudge format

One sentence of context + one actionable pointer.

```
💡 **Feature tip:** [What they could use] — [one-line why it helps here].
   → [How to invoke it]
```

Do NOT:
- Suggest the same feature twice in a session
- Suggest features not listed in `references/native-features.md` as native
- Present skill-defined commands (like `/feature-check`) as native Claude Code
- Interrupt with a wall of text

## /feature-check

When the user types `/feature-check`, run the audit pipeline as Bash
commands, in order:

1. **Refresh the knowledge base** (best-effort, silent on failure):
   ```bash
   bash ~/.claude/skills/code-whisperer/scripts/update-knowledge-base.sh >/dev/null 2>&1 || true
   ```
   Ensures the audit runs against the most recent version of
   `native-features.md`. A failed refresh does not block the audit.

2. **Run the session auditor:**
   ```bash
   bash ~/.claude/skills/code-whisperer/scripts/session-audit.sh
   ```
   This reads the current session's tool log, the native + local
   feature registries, and asks Haiku (`claude -p --bare --model
   claude-haiku-4-5-20251001 --system-prompt-file audit-prompt.txt`)
   to identify registry features that would have materially helped.
   The auditor prints structured markdown to stdout — or the exact
   sentence "No notable feature gaps in this session..." if nothing
   meaningful applies.

3. **Relay the auditor's output to the user verbatim.** Do not
   reinterpret, summarise, or re-rank it. The auditor is constrained
   to only cite features from `references/native-features.md`; you
   must not add features it didn't mention.

If the auditor returns the empty-gap message, just show it. Do not
invent features to pad the output.

If `session-audit.sh` exits non-zero (hard failure — missing files,
`claude` CLI not found), tell the user plainly what went wrong and
point them at `references/native-features.md` for a manual read.

The audit should draw on what you've actually observed in the session,
not recite the knowledge base generically.

## Knowledge base rules

- **Native features:** `references/native-features.md` — every entry
  has a source URL. Only claim something is "native Claude Code" if
  it's in this file. The file is refreshed daily by
  `scripts/update-knowledge-base.sh` (via cron or manual run); it
  reads the upstream Claude Code CHANGELOG and appends new entries.
- **Local features:** `references/local-features.md` — `/feature-check`
  and anything else this skill defines. Label clearly as "this skill
  provides…"
- **If unsure:** ask the user or say nothing. Do not invent features.

## Freshness

If `references/native-features.md` has a `last_updated` date more than
2 days old, mention that once at the start of a session where the user
asks about recent features, and suggest they run
`bash ~/.claude/skills/code-whisperer/scripts/update-knowledge-base.sh`
to refresh. Do not nag repeatedly.
