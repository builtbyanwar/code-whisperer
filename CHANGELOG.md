# Changelog

## v2.1

`/feature-check` is now session-aware. Instead of reciting the feature
registry generically, it now reads the current session's tool log and
cross-references against `references/native-features.md` via a Haiku
call, returning a short markdown report on features that would have
materially changed how the user worked in this session.

### New

- `scripts/session-audit.sh` — auditor runner. Resolves the session id
  (auto-detects the most recent, or accepts one as argument), compacts
  the tool log into a unique `(ToolName|signature, count)` list, builds
  a three-section input block (`TOOL_LOG`, `NATIVE_FEATURES`,
  `LOCAL_FEATURES`), invokes `claude -p --model
  claude-haiku-4-5-20251001 --system-prompt-file audit-prompt.txt`, and
  prints the auditor's markdown to stdout. Soft-fails on Haiku errors.
- `scripts/audit-prompt.txt` — the system prompt that constrains Haiku
  to: observe-only, registry-bound, evidence-over-generics, no padding,
  explicit empty-gap template when nothing meaningful applies.

### Changed

- `/feature-check` in SKILL.md now runs the pipeline: refresh the KB
  silently (`update-knowledge-base.sh`), run `session-audit.sh`, relay
  the output verbatim. No feature invention; Claude may not add
  features the auditor didn't mention.

### Tested

- Rich session (141 tool calls): auditor returned one well-justified
  feature with concrete tool counts and source URL.
- Light session (4 tool calls): auditor returned the exact
  empty-gap sentence without padding.
- Auto-detect (no session_id arg): picked the most recent session
  correctly.

Full evidence in `tests/feature-check-audit.md`.

### Known trade-off

The auditor invokes `claude -p` **without** `--bare`. An initial
attempt with `--bare` failed auth because that flag skips the keychain
read, leaving the subprocess unable to reach the model even when the
parent Claude Code session is logged in. Dropping `--bare` means the
subprocess inherits any ambient Claude Code config (CLAUDE.md, memory,
etc.). Testing showed no observable pollution, but if future tuning
reveals leakage, revisit with `--append-system-prompt-file` or a
direct SDK call.

## v2.0.1

Documentation and file-layout fixes. No behavior change for the hooks
shipped in v2.0. This release closes drift between SKILL.md, the update
script, and the reference files that had accumulated during the v2.0
work.

### What was broken

- **SKILL.md referenced the removed UserPromptSubmit hook** as the
  skill's primary activation mechanism. That hook was cut in v2.0 but
  the skill's own documentation never got updated.
- **`update-knowledge-base.sh` wrote to `references/feature-knowledge-base.md`**
  but SKILL.md and the installed skill only read
  `references/native-features.md` + `references/local-features.md`.
  The daily cron was updating a file nothing in the skill read.
- **Repo `references/` held the old layout** while the live installed
  skill had already moved to the native/local split.

### What changed

- SKILL.md rewritten to describe v2.0's actual activation model:
  SessionStart reminder, PostToolUse pattern-watcher, and the
  user-invoked `/feature-check` command. No more references to a
  prompt-level classifier.
- `update-knowledge-base.sh` now writes to
  `references/native-features.md`. A one-shot migration guard warns
  and exits if only the old filename is present, prompting the user
  to rename once.
- Repo `references/` resynced to the native/local split.
- Added a "Freshness" section to SKILL.md — the skill will flag a
  stale knowledge base (>2 days old) once per session when features
  are asked about, rather than silently serving stale data.

### Why v2.0.1 and not v2.1

v2.1 is scoped for session-aware `/feature-check` (using the tool-log
to identify missed features from the user's actual session). That work
needs to build on a coherent foundation, and v2.0 shipped with its
documentation and file structure out of sync. This patch gets the
project back to a state where the README, SKILL.md, scripts, and
reference files all agree on what the skill does and reads.

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
