#!/usr/bin/env bash
# code-whisperer hook installer
#
# Merges the code-whisperer SessionStart + PostToolUse hooks into the user's
# ~/.claude/settings.json. Safe to run repeatedly — it detects existing entries
# and skips them rather than duplicating.
#
# Why this exists: skill descriptions with "PROACTIVELY" are probabilistic hints
# that Claude may miss mid-task. These two hooks make feature-awareness
# deterministic:
#   - SessionStart (bash): once-per-session reminder to use the skill
#   - PostToolUse  (bash): behavioural pattern detection (sequential Tasks,
#                  repeated Bash commands, heavy Read/Grep) with
#                  one-nudge-per-pattern cooldowns per session
#
# A UserPromptSubmit Haiku classifier was piloted in pre-2.0 development and
# removed: smoke testing showed it both (a) failed to inject useful tips when
# it should have, and (b) occasionally blocked conversational prompts with
# "Operation stopped by hook" messages. The probabilistic nature of a
# per-prompt LLM gate made false blocks unavoidable. See
# tests/hook-smoke-test.md for the evidence that killed it.

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
WATCHER="$HOME/.claude/skills/code-whisperer/scripts/pattern-watcher.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq is required. Install with: brew install jq" >&2
  exit 1
fi

if [ ! -f "$SETTINGS" ]; then
  echo "⚠️  $SETTINGS not found — creating it."
  mkdir -p "$(dirname "$SETTINGS")"
  echo '{}' > "$SETTINGS"
fi

# Make the watcher executable if installed
if [ -f "$WATCHER" ]; then
  chmod +x "$WATCHER"
else
  echo "⚠️  Watcher not found at $WATCHER"
  echo "    Install the skill first: cp -r code-whisperer ~/.claude/skills/"
  exit 1
fi

backup="$SETTINGS.bak.$(date +%s)"
cp "$SETTINGS" "$backup"
echo "→ Backup written to $backup"

session_start_ctx='code-whisperer is loaded. It will quietly suggest relevant Claude Code features when it spots patterns worth flagging. Never block or evaluate user prompts — only add optional tips after responding normally.'

session_start_cmd="cat <<'EOF'
{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"$session_start_ctx\"}}
EOF"

post_tool_cmd="bash $WATCHER"

tmp="$(mktemp)"
jq \
  --arg ss_cmd "$session_start_cmd" \
  --arg pt_cmd "$post_tool_cmd" \
  '
  .hooks = (.hooks // {})
  | .hooks.SessionStart = (.hooks.SessionStart // [])
  | .hooks.PostToolUse  = (.hooks.PostToolUse // [])
  | (
      if any(.hooks.SessionStart[]?.hooks[]?; .command == $ss_cmd)
      then .
      else .hooks.SessionStart += [{"hooks": [{"type":"command","command":$ss_cmd}]}]
      end
    )
  | (
      if any(.hooks.PostToolUse[]?.hooks[]?; .command == $pt_cmd)
      then .
      else .hooks.PostToolUse += [{"matcher":"Task|Agent|Bash|Read|Grep","hooks":[{"type":"command","command":$pt_cmd}]}]
      end
    )
  ' "$SETTINGS" > "$tmp"

mv "$tmp" "$SETTINGS"
echo "✅ Hooks installed."
echo "   • SessionStart → once-per-session skill reminder"
echo "   • PostToolUse  → pattern watcher, nudges once per pattern"
echo ""
echo "Restart Claude Code to activate."
