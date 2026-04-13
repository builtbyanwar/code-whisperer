# code-whisperer

> *You've been doing it the hard way. You just didn't know there was an easier one.*

---

## You know this feeling

You spend 40 minutes carefully prompting Claude through a task — file by file, step by step, getting it done. It works. You feel good about it.

Then a week later you're watching someone else's screen and they do the exact same thing in one command. One. Command.

And you think: *how long has that existed? Why didn't I know about that?*

That's not a you problem. Anthropic ships Claude Code updates almost daily. New commands, new features, new shortcuts — each one quietly buried in a changelog that nobody has time to read. The tool you're using today is genuinely different from the one you learned last month, and there's no one tapping you on the shoulder to tell you what changed.

So you keep doing things the long way. Not because you're lazy. Not because you're bad at this. Simply because **you can't use what you don't know exists.**

---

## What code-whisperer does

It watches your session. Silently. In the background.

And when it notices you doing something the long way — something Claude Code already has a native solution for — it says something. Just once. Just a short nudge:

```
💡 Feature tip: /batch would do all of these in one shot — same prompt
   applied to multiple files in parallel, fraction of the turns.
   → Try: /batch "Add AAOIFI screening" *_screener.py
```

That's it. No lectures. No interruptions. Just the right hint at the right moment, from something that actually knows what you're doing.

---

## The moments it catches

**You're doing the same thing to multiple files, one at a time**
→ *"There's a command for that. One prompt, all files, done in parallel."*

**You're doing heavy research in your main session and watching your context fill up**
→ *"That work can run in its own window. Your main session stays clean."*

**You keep typing "are you done yet?" at a long-running task**
→ *"Claude Code can check on that for you automatically. Or just ping you when it's finished."*

**You're manually copying from GitHub into Claude every time**
→ *"There's an official GitHub connector. Claude can read your issues and PRs directly."*

**You're explaining the same project context at the start of every single session**
→ *"There's a memory system for exactly this. You explain it once. Ever."*

You can also type `/feature-check` any time and get a full honest audit: *here's what you've been doing, here's what you could have used, here's how.*

---

## Works with

| Product | Supported |
|---------|-----------|
| Claude Code (terminal) | ✅ |
| Claude Desktop — Cowork tab | ✅ |
| Claude.ai (web + mobile) | ✅ |

---

## Installation

### Claude Code (terminal)

Open your terminal and run these one at a time:

```bash
# 1. Unpack
cd ~/Downloads
tar -xzf code-whisperer.tar.gz

# 2. Install
cp -r code-whisperer ~/.claude/skills/

# 3. Make the updater runnable
chmod +x ~/.claude/skills/code-whisperer/scripts/update-knowledge-base.sh

# 4. Pull the latest features right now
bash ~/.claude/skills/code-whisperer/scripts/update-knowledge-base.sh

# 5. Restart Claude Code
claude
```

**Set up daily auto-updates** (so it always knows what's new):
```bash
crontab -e
```
Paste this at the bottom and save:
```
0 12 * * * bash ~/.claude/skills/code-whisperer/scripts/update-knowledge-base.sh
```
This runs the updater every day at noon — when your machine is more likely to be awake and running than 8am.

**One important thing to know:** if your computer is asleep, closed, or switched off at noon, the update simply skips that day. It doesn't queue up and run when you wake the machine — it just misses the window. That's completely fine. Missing a day or two has no real impact because the skill monitors its own freshness and will remind you inside your session if the knowledge base is more than 2 days old. You'll never be silently running on stale data without knowing.

To confirm everything's working, type `/feature-check` in your next session.

#### Is this skill for you?

If you already run a heavy plugin stack — particularly **superpowers**, **feature-dev**, and **ralph-loop** from the official Claude plugins marketplace — most of what code-whisperer nudges toward is already covered by those plugins' own skills and hooks. In that setup, this skill is redundant. You'll still get value from `/feature-check` and the daily changelog sync, but the pattern-watching hooks below will rarely fire because your existing plugins already push you toward parallel dispatch, the Explore subagent, `/loop`, etc.

This skill is primarily for users on a **lighter Claude Code setup** who want feature-awareness without installing the full plugin suite.

#### Optional: pattern-watching hooks (experimental)

The skill on its own relies on Claude noticing when a native feature applies. Two lightweight bash hooks make that more reliable:

- **SessionStart** — injects a one-line reminder at the top of every session, so the skill is on Claude's radar from turn one.
- **PostToolUse** — watches for behavioural patterns (3+ sequential `Task`/`Agent` calls, repeated `Bash` commands, heavy `Read`/`Grep` in the main context) and nudges once per pattern per session.

Install with:
```bash
bash ~/.claude/skills/code-whisperer/scripts/install-hooks.sh
```

The installer is idempotent, backs up your `~/.claude/settings.json` before touching it, and skips hooks that are already present. Requires `jq` (`brew install jq` if you don't have it).

To uninstall, restore the backup the installer printed, or edit the `hooks` block out of `~/.claude/settings.json` by hand.

> **Where you'll see the tip.** The watcher emits each nudge as both a `systemMessage` (meant to render as a visible banner) and an `additionalContext` entry (injected into Claude's reasoning). In the terminal `claude` CLI and most official IDE integrations, the banner appears directly in the transcript. In some third-party integrations — notably the Claude Code extension running inside Cursor — the visible banner may not render at all; in that case the tip still reaches Claude, and you'll usually see it acknowledged in Claude's next reply instead of as a distinct banner.

> **Diminishing returns with a heavy plugin stack.** If you have superpowers + feature-dev installed, the nudges here will mostly not fire — superpowers' own SessionStart and skill-enforcement logic gets there first, and you're already running parallel agents and Explore subagents by habit. That's fine; the pattern watcher stays silent when it has nothing useful to say.

> **Note on a piloted third hook.** An earlier draft included a `UserPromptSubmit` Haiku classifier that would read each prompt and optionally inject a feature tip. It was cut before v2.0: smoke testing showed it both under-fired (no tips across 4 clear technical prompts where one could have helped) and over-fired (blocked conversational prompts with "Operation stopped by hook"). A per-prompt LLM gate is the wrong shape for this — too much blast radius for too little signal. The evidence lives in `tests/hook-smoke-test.md`.

---

### Claude Desktop (Cowork tab)

1. Open Claude Desktop
2. Go to **Settings → Skills**
3. Click **Add skill** → upload `code-whisperer.tar.gz`

Done. It's active in every Cowork session from here on.

---

### Claude.ai (web or mobile)

1. Go to **Settings → Skills**
2. Click **Add skill** → upload the `SKILL.md` file from inside the folder

One note: the daily auto-update only runs on your local machine. On claude.ai, re-upload the skill every few weeks to keep the knowledge base current.

---

## Staying current

The skill knows what Claude Code can do from a knowledge base at `references/feature-knowledge-base.md`. The cron job keeps it fresh by fetching Anthropic's official changelog every day at noon.

**If your machine was asleep at noon** — no problem. The update just skips that day. The skill will flag it inside your session if things go stale, so you always know where you stand.

**If you skipped the cron job entirely**, run this manually whenever you want a refresh:
```bash
bash ~/.claude/skills/code-whisperer/scripts/update-knowledge-base.sh
```

The skill checks its own freshness every session and will remind you if it's been more than 2 days since the last update. You won't be silently working with outdated information.

---

## Security & privacy

We know this matters. So here's the complete picture — nothing hidden.

**The only external connections this skill makes:**

When the update script runs, it reads from exactly two URLs:
- `raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` — Anthropic's official GitHub, read-only
- `code.claude.com/docs/en/changelog` — Anthropic's official docs, read-only fallback

That's the entire surface area. Two read-only requests to Anthropic's own servers, once a day, to fetch a public changelog.

**What never happens:**

- Your code is never sent anywhere
- Your prompts are never logged or transmitted
- Your session content never leaves your machine
- There is no analytics, no tracking, no telemetry
- There is no server of ours receiving anything

**The trust model:**

This skill is entirely plain text — one markdown file, one bash script, one reference document. No compiled code. No binaries. Nothing you can't open in a text editor right now and read line by line before you install anything. That transparency is intentional. You shouldn't have to take our word for it.

---

## Contributing

If you spot a pattern the skill misses, or know a better way to describe a trigger — open a PR. The `references/feature-knowledge-base.md` file is the main place to contribute and the barrier to entry is low: it's just a markdown table.

---

## Licence

MIT. Free to use, share, and modify. If you make it better, consider sharing back.
