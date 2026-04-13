#!/usr/bin/env bash
# code-whisperer PostToolUse watcher
#
# Reads the JSON hook payload on stdin, tracks recent tool-use patterns in a
# per-session state file, and emits a one-time nudge when it detects:
#   - 3+ sequential Task calls           → suggest parallel dispatch
#   - 4+ same-shape Bash commands        → suggest /batch
#   - 8+ Read/Grep in a row              → suggest Explore subagent
#
# Each pattern nudges at most once per session (cooldown via marker files).
# Silent on no-match — never spams.

set -euo pipefail

# Read hook payload
payload="$(cat)"

# Extract session id and tool name. Fall back quietly if jq is missing.
if command -v jq >/dev/null 2>&1; then
  session_id="$(printf '%s' "$payload" | jq -r '.session_id // "unknown"')"
  tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // "unknown"')"
  tool_input="$(printf '%s' "$payload" | jq -r '.tool_input // {} | tostring')"
else
  exit 0
fi

[ "$session_id" = "unknown" ] && exit 0

state_dir="${TMPDIR:-/tmp}/code-whisperer/$session_id"
mkdir -p "$state_dir"

log_file="$state_dir/tools.log"
# Keep log bounded
if [ -f "$log_file" ] && [ "$(wc -l < "$log_file" | tr -d ' ')" -gt 200 ]; then
  tail -n 100 "$log_file" > "$log_file.tmp" && mv "$log_file.tmp" "$log_file"
fi

# Record: tool_name + short signature
signature=""
case "$tool_name" in
  Bash)
    cmd="$(printf '%s' "$tool_input" | jq -r '.command // ""' 2>/dev/null || echo "")"
    # Signature = first word + second word (e.g. "python -m", "npm run")
    signature="$(printf '%s' "$cmd" | awk '{print $1, $2}')"
    ;;
esac
echo "$tool_name|$signature" >> "$log_file"

emit_nudge() {
  local key="$1" message="$2"
  local marker="$state_dir/nudged-$key"
  [ -f "$marker" ] && return 0
  touch "$marker"
  # Emit structured hook output so Claude sees it as additionalContext
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"💡 code-whisperer: $message"}}
EOF
}

# --- Pattern detection (last N entries) ---

tail_n() { tail -n "$1" "$log_file" 2>/dev/null || true; }

# 1. Sequential Task calls (>= 3 in last 4 tool uses)
task_count="$(tail_n 4 | grep -c '^Task|' || true)"
if [ "${task_count:-0}" -ge 3 ]; then
  emit_nudge "parallel-tasks" "You've dispatched $task_count Task agents sequentially. If they're independent, launching them in a single message runs them in parallel — see the superpowers:dispatching-parallel-agents skill or the Agent tool's parallel-call guidance."
  exit 0
fi

# 2. Repeated Bash signatures (same first-two-words >= 4 in last 8)
top_bash="$(tail_n 8 | awk -F'|' '$1=="Bash" && $2!="" {print $2}' | sort | uniq -c | sort -rn | head -n1 || true)"
if [ -n "$top_bash" ]; then
  bash_n="$(printf '%s' "$top_bash" | awk '{print $1}')"
  bash_sig="$(printf '%s' "$top_bash" | sed 's/^ *[0-9]* //')"
  if [ "${bash_n:-0}" -ge 4 ]; then
    emit_nudge "batch-bash" "You've run '$bash_sig ...' $bash_n times in a row. /batch applies the same operation across many inputs in one turn — worth checking if it fits here."
    exit 0
  fi
fi

# 3. Heavy Read/Grep in main context (>= 8 in last 12)
explore_count="$(tail_n 12 | grep -cE '^(Read|Grep)\|' || true)"
if [ "${explore_count:-0}" -ge 8 ]; then
  emit_nudge "explore-subagent" "$explore_count Read/Grep calls recently — that's heavy exploration in the main context. The Explore subagent (Agent tool, subagent_type=Explore) keeps your main context clean and returns a summary instead of raw file contents."
  exit 0
fi

exit 0
