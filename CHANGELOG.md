# Changelog

## v2.0

Hook installer is now **two bash hooks, both deterministic**:

- **SessionStart** — once-per-session skill reminder.
- **PostToolUse** — ambient pattern detection via `pattern-watcher.sh`
  (sequential Task/Agent calls, repeated Bash, heavy Read/Grep), one
  nudge per pattern per session.

### Nudges are now user-visible

Earlier versions emitted nudges only as `additionalContext` — a field that
injects text into Claude's context but is **never shown to the user**.
Smoke testing confirmed Claude often read the tip and chose not to relay
it. The point of the skill is the user seeing the tip.

The watcher now emits both:

- **`systemMessage`** — shown directly to the user in the terminal UI.
- **`additionalContext`** — kept so Claude can also act on the tip
  (e.g. rewrite its next reply to use the suggested feature).

### Dropped the `parallel-tasks` nudge

The "3+ sequential Task/Agent dispatches" pattern turned out not to be
reliably detectable. In real sessions, each Agent call is followed by
15–25 supporting Bash/Read/Grep calls (processing output, prepping the
next dispatch), so no fixed tail-window can distinguish "three Agents
that should have been parallel" from "three Agents across different
phases of a long task." Rather than ship a nudge that fires on the
wrong signal, it's removed. `superpowers:dispatching-parallel-agents`
already covers the use case via its skill description.

### Bugfixes

- **Installer matcher** now covers both `Task` and `Agent` as tool names
  (current Claude Code reports `Agent`; older installs used `Task`).
  Matters less now that the parallel-tasks nudge is gone, but keeps the
  watcher future-proof if other Agent-based patterns are added.

### Positioning

README now says clearly: if you run a heavy plugin stack (superpowers,
feature-dev, ralph-loop), the pattern-watching hooks are largely
redundant and this skill's main value is `/feature-check` and the daily
changelog sync. For lighter setups, the hooks are still worth having.

### A Haiku classifier was piloted and removed

Earlier drafts of v2.0 included a `UserPromptSubmit` hook: a Haiku
model call on every prompt that would optionally inject a feature tip.
Smoke testing against 12 prompts (4 conversational, 4 technical, 4
ambiguous) showed two disqualifying behaviors:

1. **Under-fired.** Zero tips across 4 clear technical-goal prompts
   that each mapped to a documented native feature (`/batch`, `/loop`,
   Explore subagent, `/schedule`). The base model routes to the
   relevant skill on its own in most of those cases, leaving the
   classifier no real gap to fill.
2. **Over-fired.** Occasionally blocked conversational prompts with
   `Operation stopped by hook`, including prompts with no technical
   content at all ("could it be because…?"). Tightening the prompt
   in 77645c7 reduced but did not eliminate this. A per-prompt LLM
   gate will always have some false-block rate; on the hot path of
   every single user turn, any non-zero false-block rate is
   unacceptable.

The right shape for feature nudging turns out to be deterministic bash:
matching observed behaviour (tool-call sequences) rather than
interpreting intent from natural language. The two remaining hooks
reflect that.

### Correction to v1.x commit history

Commit `61a2be9` was titled *"Add deterministic feature-nudging hooks"*.
Accurate for SessionStart and PostToolUse, which are pure bash. The
`UserPromptSubmit` hook added to some live installs in parallel was
Haiku-based and therefore probabilistic — that mislabel is part of
what masked the bug that eventually killed the hook.

## v1.x

- Skill: `code-whisperer` with `/feature-check` command.
- Daily cron updater for `references/feature-knowledge-base.md`.
- Initial hook installer: SessionStart + PostToolUse only.
- 77645c7: tightened wording in skill and SessionStart hook to
  prevent Claude from interpreting its role as blocking prompts.
