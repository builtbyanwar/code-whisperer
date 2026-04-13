# Local / Skill-Defined Features

> These are features defined by this skill or by other user-installed skills.
> They are **NOT native Claude Code capabilities**. Do NOT present them to the
> user as if they were shipped by Anthropic.

---

## /feature-check (defined by this skill)

- **What:** Triggers a structured audit of the current session against
  `native-features.md` to surface 3–5 features that would materially change
  how the user is working.
- **Invoke:** User types `/feature-check`
- **Where it lives:** The code-whisperer skill at `~/.claude/skills/code-whisperer/`
- **When to reference:** You can tell the user "/feature-check exists in this
  skill" but never imply it ships with Claude Code.

---

## Rule: framing custom vs native

When suggesting something:

- **If it's in `native-features.md`** → refer to it as a Claude Code feature.
- **If it's here** → say "this skill provides /feature-check …" or similar.
- **If it's from another skill or plugin the user has installed** → name the
  skill/plugin explicitly (e.g., "the superpowers plugin's `/brainstorm`").
- **If you don't know** → don't suggest it. Ask the user or skip.
