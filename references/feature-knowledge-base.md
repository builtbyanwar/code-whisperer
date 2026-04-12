# Claude Code Feature Knowledge Base

> last_updated: 2026-04-11
> source: https://code.claude.com/docs/en/changelog + https://code.claude.com/docs/en/best-practices
> next_update: run scripts/update-knowledge-base.sh

---

## Recent Releases (Last 30 Days) — Highest Priority

These are the features most likely to be unknown to even active users. Suggest these first.

### /powerup (v2.1.90 — April 1, 2026)
- **What:** Interactive in-terminal tutorial system with animated demos of Claude Code features
- **Invoke:** `/powerup`
- **Suggest when:** User seems unaware of a major feature category (hooks, subagents, voice, plan mode)
- **Key insight:** Faster than docs — learns by doing inside the terminal

### Named subagents in @ mentions (v2.1.89 — April 1, 2026)
- **What:** Custom subagents now appear in @ mention typeahead — reference them by name mid-session
- **Invoke:** `@subagent-name` in your prompt
- **Suggest when:** User has custom subagents but is invoking them via long natural language prompts

### PermissionDenied hook (v2.1.89)
- **What:** Fires after auto-mode classifier denials — return `{retry: true}` to let the model retry
- **Suggest when:** User is frustrated by auto-mode blocking certain commands repeatedly

### Defer permission decision (v2.1.89)
- **What:** Headless sessions can pause at a tool call and resume later with `-p --resume`
- **Suggest when:** User is running long automated pipelines that occasionally need human approval

### MCP tool result persistence (v2.1.91)
- **What:** MCP tools can now return up to 500K chars via `_meta["anthropic/maxResultSizeChars"]`
- **Suggest when:** User is building MCP integrations and hitting result truncation

---

## Core Feature Catalogue

### Subagents & Orchestration

#### Built-in Subagents
- **Explore** — fast read-only codebase search, runs in separate context
  - Trigger: "search through the codebase", "find all instances of X"
  - Invoke: Claude delegates automatically in plan mode; or ask explicitly
- **Plan subagent** — research before planning, prevents infinite nesting
  - Trigger: Shift+Tab to enter plan mode
- **General-purpose subagent** — complex multi-step tasks

#### Custom Subagents
- **What:** `.claude/agents/your-agent.md` with YAML frontmatter + system prompt
- **Key benefit:** Runs in its own context window — doesn't burn your main conversation
- **Suggest when:** User is doing heavy research/analysis in the main thread
- **User-level:** `~/.claude/agents/` (available across all projects)
- **Project-level:** `.claude/agents/` (project-specific)

#### Agent Teams (Research Preview)
- **What:** Multiple agents collaborating across separate sessions with shared task lists
- **Enable:** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- **Suggest when:** User has genuinely parallel workstreams on the same codebase
- **Note:** Requires explicit setup; subagents are simpler for most cases

### Slash Commands & Workflows

| Command | What it does | Suggest when |
|---------|-------------|--------------|
| `/batch` | Run same prompt across multiple files in parallel | User doing repetitive per-file tasks |
| `/loop` | Repeat a prompt within a session for polling | User checking on something periodically |
| `/schedule` | Create recurring or on-demand cloud tasks | User wants Claude to run something later |
| `/powerup` | Interactive feature tutorials | User unfamiliar with a feature category |
| `/feature-check` | Full feature-relevance review (this skill) | User wants a comprehensive audit |
| `/compact` | Summarise context to free up window | Context getting large mid-session |
| `/resume` | Resume any past session | User starting fresh unnecessarily |
| `/effort` | Set reasoning effort (low/medium/high) | User on simple tasks burning high effort |
| `/batch` | Parallel file operations | Any "do X across all files" request |
| `/add-dir` | Add extra directory to context | User referencing external project |

### Hooks System

Hooks let you run scripts automatically at Claude Code lifecycle events.

| Hook | When it fires | Key use case |
|------|--------------|--------------|
| `PreToolUse` | Before any tool call | Block/modify dangerous commands |
| `PostToolUse` | After any tool call | Format-on-save, auto-lint |
| `SessionStart` | On session start | Load project context, env setup |
| `SessionEnd` | On session end | Log summary, commit reminder |
| `Stop` | When Claude stops | Notification, next-step trigger |
| `PermissionDenied` | On auto-mode denial | Retry logic |

**Suggest hooks when:** User is manually running the same command after each edit,
wants notifications when tasks complete, or needs guardrails on certain operations.

**Configure:** `/hooks` menu, or edit `~/.claude/settings.json`

### MCP Servers (Official & Popular)

| Server | What it does | Install |
|--------|-------------|---------|
| GitHub MCP | Issues, PRs, repo management | `claude mcp add github` |
| Supabase MCP | Database ops, auth, storage | Via plugin marketplace |
| Playwright MCP | Browser automation, e2e testing | Via plugin marketplace |
| Atlassian MCP | Jira + Confluence | `claude mcp add atlassian` |
| Context7 | Live versioned library docs | Via plugin marketplace |

**Suggest when:** User is manually copy-pasting from GitHub UI, writing SQL in chat,
or referencing library docs that might be outdated.

### Skills System

- **What:** `.claude/skills/your-skill/SKILL.md` — auto-invoked expertise modules
- **vs CLAUDE.md:** Skills load on demand; CLAUDE.md loads every session
- **User-level:** `~/.claude/skills/` (across all projects)
- **Project-level:** `.claude/skills/` (project-specific)
- **Proactive:** Add "use PROACTIVELY" to description for auto-invocation
- **Suggest when:** User keeps re-explaining the same domain context each session

### Plugins

- **Browse:** `/plugin` command or `claude.com/plugins`
- **Install:** `/plugin install plugin-name`
- **Key ones:**
  - `codex-plugin-cc` — Codex adversarial review + background task delegation (official, by OpenAI)
  - `context7` — Always-current library docs
  - `pr-review-toolkit` — Multi-agent PR review
  - `feature-dev` — Guided feature development workflow

### Remote & Mobile

- **Remote Control:** Continue terminal sessions from phone/browser
- **Teleport:** `claude --teleport` — pull a terminal session into Desktop app
- **Slack integration:** Mention `@Claude` in Slack to dispatch tasks
- **Mobile dispatch:** Send task from phone, Claude runs on your machine

**Suggest when:** User mentions wanting to check on a running task from elsewhere.

### Memory & Context

- **Auto memories:** Claude automatically records and recalls patterns as it works
- **CLAUDE.md:** Project constitution — loaded every session
  - Keep concise; bloated CLAUDE.md causes Claude to miss instructions
  - Use HTML comments for notes you don't want Claude to see
- **`/compact`:** Summarise and compress context mid-session
- **`/stats`:** See token usage breakdown including subagents

### Performance & Cost

- **Effort control:** `/effort low|medium|high` — defaults to high for API users
- **Haiku routing:** Subagents default to Sonnet; specify `model: haiku` in agent frontmatter for cheap tasks
- **Context compaction:** Auto-compact fires at 95% — use `/compact` proactively at 50% for better summaries
- **Strategic compact skill:** Available in community — triggers `/compact` at logical breakpoints

### Voice Mode
- **What:** Talk to your terminal — voice input for prompts
- **Platform:** macOS, some Linux terminals
- **Suggest when:** User is doing iterative back-and-forth that would be faster spoken

### Channels (Research Preview)
- **What:** MCP servers push messages into your session; permission relay to your phone
- **Enable:** `--channels` flag
- **Suggest when:** User wants real-time updates from external systems mid-session

---

## Pattern Library: User Behaviour → Feature

| If user is doing this... | Suggest this |
|--------------------------|--------------|
| Copy-pasting same prompt for each file | `/batch` |
| Running research in main thread | Explore subagent |
| Checking on a task periodically | `/loop` or background agent |
| Wanting to run something overnight | `/schedule` |
| Manually running lint/format after edits | `PostToolUse` hook |
| Getting desktop notification on finish | `Stop` hook |
| Re-explaining project context each session | CLAUDE.md or a skill |
| Fetching library docs that might be stale | Context7 MCP |
| Managing GitHub issues/PRs manually | GitHub MCP |
| Wanting a second opinion on code | Codex plugin (`/codex:adversarial-review`) |
| Running long sequential tasks | Agent Teams or parallel subagents |
| Working across multiple project dirs | `--add-dir` or `/add-dir` |
| Worried about context filling up | `/compact` + `/stats` |
| Wanting to keep working on mobile | Remote Control + Teleport |
| Doing the same db queries repeatedly | Supabase MCP |
| Writing browser tests manually | Playwright MCP |
| Frustrated by repeated permission prompts | `PreToolUse` hook + auto-mode tuning |

---

## Data Sources for Updates

- **Changelog:** https://code.claude.com/docs/en/changelog
- **GitHub releases:** https://github.com/anthropics/claude-code/releases
- **Best practices:** https://code.claude.com/docs/en/best-practices
- **Plugin directory:** https://claude.com/plugins
- **Anthropic platform notes:** https://platform.claude.com/docs/en/release-notes/overview
