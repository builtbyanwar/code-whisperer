#!/usr/bin/env bash
# session-audit.sh
#
# Produces a session-aware feature audit for `/feature-check`. Reads the
# tool log written by pattern-watcher.sh, combines it with the native +
# local feature registries, and asks claude-haiku-4-5 to identify
# features from the registry that would have materially helped the user.
#
# Usage: bash session-audit.sh <session_id>
# Or:    bash session-audit.sh        # auto-selects most recent session
#
# Exits 0 on success (audit printed to stdout).
# Exits non-zero only on hard failures (missing files, no claude CLI).
# Haiku failures fall back to a one-line message, not an error.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT_PROMPT="$SKILL_DIR/scripts/audit-prompt.txt"
NATIVE_FEATURES="$SKILL_DIR/references/native-features.md"
LOCAL_FEATURES="$SKILL_DIR/references/local-features.md"
STATE_ROOT="${TMPDIR:-/tmp}/code-whisperer"

# ── Input validation ────────────────────────────────────────────────────────
for f in "$AUDIT_PROMPT" "$NATIVE_FEATURES" "$LOCAL_FEATURES"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: required file missing: $f" >&2
    exit 1
  fi
done

if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: claude CLI not found on PATH. /feature-check audit needs it." >&2
  exit 1
fi

# ── Resolve session_id ──────────────────────────────────────────────────────
session_id="${1:-}"
if [ -z "$session_id" ]; then
  # Auto-select: most recently modified session dir under STATE_ROOT.
  if [ ! -d "$STATE_ROOT" ]; then
    echo "No session state directory at $STATE_ROOT." >&2
    echo "Either the PostToolUse watcher hasn't run yet this install, or" >&2
    echo "no tool calls have been logged. Try running a Bash/Read/Grep call" >&2
    echo "first, then re-invoke /feature-check." >&2
    exit 1
  fi
  session_id="$(ls -t "$STATE_ROOT" 2>/dev/null | head -n 1 || true)"
  if [ -z "$session_id" ]; then
    echo "No sessions found under $STATE_ROOT." >&2
    exit 1
  fi
fi

tool_log="$STATE_ROOT/$session_id/tools.log"
if [ ! -f "$tool_log" ]; then
  echo "No tool log for session $session_id at $tool_log." >&2
  echo "Either the session hasn't run any matched tools, or the session_id is wrong." >&2
  exit 1
fi

# ── Build combined input ────────────────────────────────────────────────────
# Compact the tool log to unique (tool, signature) counts to save tokens.
# Order is preserved via the first-appearance line number.
compacted_log="$(awk -F'|' '
  { key=$0; if (!(key in seen)) { seen[key]=NR; order[++n]=key } count[key]++ }
  END {
    for (i=1; i<=n; i++) {
      k=order[i]; printf "%s  (×%d)\n", k, count[k]
    }
  }
' "$tool_log")"

combined_input="$(cat <<EOF
---SECTION: TOOL_LOG---
Session: $session_id
Unique tool+signature entries (with occurrence counts, in first-seen order):

$compacted_log

Total tool calls in session: $(wc -l < "$tool_log" | tr -d ' ')

---SECTION: NATIVE_FEATURES---
$(cat "$NATIVE_FEATURES")

---SECTION: LOCAL_FEATURES---
$(cat "$LOCAL_FEATURES")
EOF
)"

# ── Invoke Haiku ────────────────────────────────────────────────────────────
# We do NOT pass --bare here: --bare skips the auth keychain read, which
# means the spawned subprocess has no way to authenticate even when the
# user is logged into the running Claude Code session. --system-prompt-file
# alone gives us enough control over the model's behavior (testing shows
# Haiku respects the audit prompt's strict rules and returns the exact
# "No notable feature gaps" sentence when appropriate).
audit_output="$(
  printf '%s' "$combined_input" \
  | claude -p \
      --model claude-haiku-4-5-20251001 \
      --system-prompt-file "$AUDIT_PROMPT" \
      2>/dev/null
)" || {
  echo "⚠️  Audit call failed. The Haiku invocation returned a non-zero exit."
  echo "    Possible causes: no auth, rate limit, network issue, or claude CLI change."
  echo "    The skill's static knowledge base at $NATIVE_FEATURES is still accurate;"
  echo "    you can read it directly if needed."
  exit 0
}

if [ -z "$audit_output" ]; then
  echo "⚠️  Audit returned an empty response. Not printing a fake report."
  exit 0
fi

printf '%s\n' "$audit_output"
