# Native Claude Code Features — Verified Registry

> last_updated: 2026-04-13
> Every entry MUST include a source URL and a version where applicable.
> If a claim cannot be sourced, move it to local-features.md or delete it.

---

## How to use this file

Only suggest features listed here as **native Claude Code capabilities**. Anything
not in this file but relevant to the user's workflow must either be sourced and
added, or described as "community/local" via `local-features.md`.

---

## Recent Releases (source: https://code.claude.com/docs/en/changelog)

### /team-onboarding (v2.1.101)
- **What:** Generates a teammate ramp-up guide from local Claude Code usage patterns
- **Invoke:** `/team-onboarding`
- **Source:** https://code.claude.com/docs/en/changelog (v2.1.101)
- **Suggest when:** User is onboarding teammates or sharing their setup

### OS CA certificate store trust (v2.1.101)
- **What:** Enterprise TLS proxies work by default; `CLAUDE_CODE_CERT_STORE=bundled` opts out
- **Source:** https://code.claude.com/docs/en/changelog (v2.1.101)
- **Suggest when:** User behind a corporate proxy hitting TLS errors

### /ultraplan auto-environment (v2.1.101)
- **What:** `/ultraplan` auto-creates a default cloud environment
- **Source:** https://code.claude.com/docs/en/changelog (v2.1.101)
- **Suggest when:** User wants ultraplan without manual cloud setup

### Interactive Vertex AI / Bedrock setup wizards (v2.1.98, v2.1.92)
- **What:** Guided auth + project + credential verification from the login screen
- **Source:** https://code.claude.com/docs/en/changelog
- **Suggest when:** First-time GCP/AWS auth setup

### CLAUDE_CODE_PERFORCE_MODE (v2.1.98)
- **What:** Edit/Write fails on read-only files with `p4 edit` hint
- **Source:** https://code.claude.com/docs/en/changelog (v2.1.98)
- **Suggest when:** User works in a Perforce repo

### Monitor tool (v2.1.98)
- **What:** Streams events from background processes in real time
- **Source:** https://code.claude.com/docs/en/changelog (v2.1.98)
- **Suggest when:** User is polling a long-running background script

### /agents tabbed layout with Running tab (v2.1.98)
- **What:** Live view of running subagents with run/view actions
- **Source:** https://code.claude.com/docs/en/changelog (v2.1.98)
- **Suggest when:** User is juggling multiple background agents

### --teleport (Desktop handoff)
- **What:** Pull an active terminal session into the Desktop app
- **Invoke:** `claude --teleport`
- **Source:** https://code.claude.com/docs/en/cli-reference
- **Suggest when:** User wants to continue a session on mobile/desktop

---

## Core Features (source: https://code.claude.com/docs/en/)

### Subagents
- **Explore** — read-only codebase search in a separate context
- **Plan subagent** — research before planning
- **General-purpose** — complex multi-step tasks
- **Custom subagents:** `.claude/agents/*.md` (project) or `~/.claude/agents/` (user)
- **Source:** https://code.claude.com/docs/en/subagents
- **Suggest when:** User is doing heavy research/analysis in the main thread

### Agent Teams (research preview)
- **Enable:** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- **Source:** https://code.claude.com/docs/en/changelog
- **Suggest when:** User has genuinely parallel workstreams

### Slash Commands (built-in)
| Command | What | Source |
|---------|------|--------|
| `/batch` | Same prompt across many files in parallel | https://code.claude.com/docs/en/slash-commands |
| `/loop` | Repeat a prompt within a session (polling) | https://code.claude.com/docs/en/slash-commands |
| `/schedule` | Recurring or on-demand cloud tasks | https://code.claude.com/docs/en/slash-commands |
| `/powerup` | Interactive in-terminal tutorials | https://code.claude.com/docs/en/changelog (v2.1.90) |
| `/compact` | Summarise context to free up window | https://code.claude.com/docs/en/slash-commands |
| `/resume` | Resume a past session | https://code.claude.com/docs/en/slash-commands |
| `/effort` | Set reasoning effort | https://code.claude.com/docs/en/slash-commands |
| `/add-dir` | Add extra directory to context | https://code.claude.com/docs/en/slash-commands |
| `/cost` | Per-model + cache-hit breakdown | https://code.claude.com/docs/en/slash-commands |
| `/hooks` | Manage hooks via UI | https://code.claude.com/docs/en/hooks |
| `/plugin` | Browse/install plugins | https://code.claude.com/docs/en/plugins |
| `/release-notes` | Interactive version picker | https://code.claude.com/docs/en/changelog (v2.1.92) |
| `/stats` | Token usage breakdown incl. subagents | https://code.claude.com/docs/en/slash-commands |
| `/agents` | Manage running agents | https://code.claude.com/docs/en/changelog (v2.1.98) |

### Hooks
| Event | Fires when | Source |
|-------|-----------|--------|
| `PreToolUse` | Before a tool call | https://code.claude.com/docs/en/hooks |
| `PostToolUse` | After a tool call | https://code.claude.com/docs/en/hooks |
| `UserPromptSubmit` | Every user prompt | https://code.claude.com/docs/en/hooks |
| `SessionStart` | On session start | https://code.claude.com/docs/en/hooks |
| `SessionEnd` | On session end | https://code.claude.com/docs/en/hooks |
| `Stop` | When Claude stops | https://code.claude.com/docs/en/hooks |
| `PermissionDenied` | On auto-mode denial | https://code.claude.com/docs/en/hooks |
| `PreCompact` / `PostCompact` | Around compaction | https://code.claude.com/docs/en/hooks |

**Suggest hooks when:** user wants deterministic, event-driven automation —
NOT for behaviour that depends on Claude "remembering" to do something.

### MCP Servers
- **Docs:** https://code.claude.com/docs/en/mcp
- Well-known: GitHub, Atlassian, Playwright, Context7, Supabase
- **Suggest when:** User is manually copy-pasting from external tools

### Skills
- **What:** `.claude/skills/<name>/SKILL.md` — on-demand expertise modules
- **Source:** https://code.claude.com/docs/en/skills
- **Important caveat:** "PROACTIVELY" in a skill description is a **selection
  heuristic**, not a guaranteed auto-invocation mechanism. Descriptions are
  truncated at ~250 characters when Claude is deciding whether to invoke a skill.
  For deterministic behaviour, use a hook.

### Remote & Mobile
- **Remote Control:** Continue sessions from phone/browser — https://code.claude.com/docs/en/
- **Teleport:** `claude --teleport`
- **Slack integration:** `@Claude` mention dispatches a task
- **Source:** https://code.claude.com/docs/en/changelog

### Plugins (selected)
- `codex-plugin-cc` (OpenAI) — adversarial review + task delegation
- `context7` — live library docs
- `pr-review-toolkit` — multi-agent PR review
- `feature-dev` — guided feature development
- **Browse:** https://claude.com/plugins

### Voice & Channels
- **Voice:** Hold-to-talk dictation (macOS + some Linux)
- **Channels:** MCP servers push messages into session via `--channels` flag
- **Source:** https://code.claude.com/docs/en/changelog

### Memory & Context
- **Auto memory:** Per-project notes Claude maintains across sessions
- **CLAUDE.md:** Loaded every session — keep concise
- **`/compact`:** Manual summarisation; auto fires at ~95% context
- **Source:** https://code.claude.com/docs/en/memory

### Performance
- **Effort levels:** `/effort low|medium|high`
- **Haiku routing:** Specify `model: haiku` in subagent frontmatter for cheap tasks
- **Source:** https://code.claude.com/docs/en/changelog

---

## Pattern Library: User Outcome → Native Feature

| User is trying to... | Suggest |
|----------------------|---------|
| Run same prompt across many files | `/batch` |
| Do heavy codebase research | Explore subagent |
| Check on a task periodically | `/loop` or background subagent |
| Run something overnight / recurring | `/schedule` |
| Auto-format after edits | `PostToolUse` hook |
| Get notified when done | `Stop` hook |
| Preserve project conventions across sessions | CLAUDE.md or a skill |
| Reference external project dir | `/add-dir` |
| Manage context bloat | `/compact` + `/stats` |
| Parallelise truly independent tasks | Parallel subagents or Agent Teams |
| Continue on phone | Remote Control + Teleport |
| Block or modify risky commands | `PreToolUse` hook |
| Get a second opinion on code | Codex plugin |
| Keep library docs current | Context7 plugin |
| Manage GitHub from the terminal | GitHub MCP |

---

## Data Sources (for manual verification)

- Changelog: https://code.claude.com/docs/en/changelog
- Docs: https://code.claude.com/docs/en/
- Hooks: https://code.claude.com/docs/en/hooks
- Slash commands: https://code.claude.com/docs/en/slash-commands
- Skills: https://code.claude.com/docs/en/skills
- Plugin directory: https://claude.com/plugins
