#!/usr/bin/env bash
# update-knowledge-base.sh
# Run daily (or manually) to refresh the feature knowledge base from official Anthropic sources.
# Usage: bash ~/.claude/skills/code-whisperer/scripts/update-knowledge-base.sh
# Cron: 0 8 * * * bash ~/.claude/skills/code-whisperer/scripts/update-knowledge-base.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KB_FILE="$SKILL_DIR/references/native-features.md"
BACKUP_FILE="$KB_FILE.backup"
LOG_FILE="$SKILL_DIR/scripts/update.log"
TODAY=$(date +%Y-%m-%d)

# Back-compat: v2.0 and earlier used feature-knowledge-base.md. If only the
# old file exists, refuse to run rather than silently writing to a file the
# skill no longer reads. User must rename once.
if [ ! -f "$KB_FILE" ] && [ -f "$SKILL_DIR/references/feature-knowledge-base.md" ]; then
  echo "⚠️  Found feature-knowledge-base.md but no native-features.md." >&2
  echo "    v2.0.1 renamed the canonical knowledge base. One-time migration:" >&2
  echo "      mv \"$SKILL_DIR/references/feature-knowledge-base.md\" \"$KB_FILE\"" >&2
  echo "    Then re-run this script." >&2
  exit 1
fi

echo "[$TODAY] Starting knowledge base update..." | tee -a "$LOG_FILE"

# ── Check dependencies ──────────────────────────────────────────────────────
check_dep() {
  if ! command -v "$1" &>/dev/null; then
    echo "ERROR: $1 not found. Install it first." | tee -a "$LOG_FILE"
    exit 1
  fi
}
check_dep curl
check_dep claude   # We use claude -p to summarise new entries

# ── Backup current KB ───────────────────────────────────────────────────────
cp "$KB_FILE" "$BACKUP_FILE"
echo "  Backed up existing knowledge base." | tee -a "$LOG_FILE"

# ── Fetch latest changelog ──────────────────────────────────────────────────
echo "  Fetching Claude Code changelog..." | tee -a "$LOG_FILE"
CHANGELOG_RAW=$(curl -sf \
  "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md" \
  2>/dev/null) || {
    echo "  WARNING: Could not fetch GitHub changelog. Trying docs..." | tee -a "$LOG_FILE"
    CHANGELOG_RAW=""
}

# Fallback: fetch from docs site
if [ -z "$CHANGELOG_RAW" ]; then
  CHANGELOG_RAW=$(curl -sf \
    "https://code.claude.com/docs/en/changelog" \
    2>/dev/null | sed 's/<[^>]*>//g' | sed '/^[[:space:]]*$/d' | head -200) || {
      echo "  ERROR: Could not fetch changelog from any source." | tee -a "$LOG_FILE"
      echo "  Knowledge base NOT updated." | tee -a "$LOG_FILE"
      exit 1
  }
fi

# ── Extract recent entries (last 30 days) ───────────────────────────────────
echo "  Extracting recent entries..." | tee -a "$LOG_FILE"

# Get current last_updated from KB
CURRENT_LAST_UPDATE=$(grep "^> last_updated:" "$KB_FILE" | head -1 | awk '{print $3}')
echo "  Current KB date: $CURRENT_LAST_UPDATE" | tee -a "$LOG_FILE"

# ── Ask Claude to summarise new entries into KB format ──────────────────────
echo "  Asking Claude to extract new features from changelog..." | tee -a "$LOG_FILE"

CURRENT_KB=$(cat "$KB_FILE")

NEW_FEATURES=$(echo "$CHANGELOG_RAW" | claude -p "
You are updating a Claude Code feature knowledge base.

CURRENT KNOWLEDGE BASE (for context on what's already known):
---
$(head -80 "$KB_FILE")
---

NEW CHANGELOG CONTENT:
---
$CHANGELOG_RAW
---

Tasks:
1. Identify any entries in the changelog that are NOT already covered in the knowledge base
2. Focus ONLY on user-facing features (Added/Improved items), skip bug fixes
3. For each genuinely new feature, produce a short entry in this format:

### Feature Name (vX.X.X — Date)
- **What:** One sentence description
- **Invoke:** How to use it (command, flag, or setting)
- **Suggest when:** The user behaviour pattern that should trigger this suggestion

If there are no new features since the current KB date ($CURRENT_LAST_UPDATE), output exactly: NO_NEW_FEATURES

Output ONLY the new entries or NO_NEW_FEATURES. No preamble.
" 2>/dev/null) || {
  echo "  WARNING: Claude summarisation failed. Knowledge base not updated." | tee -a "$LOG_FILE"
  exit 1
}

if [ "$NEW_FEATURES" = "NO_NEW_FEATURES" ]; then
  echo "  No new features found. Knowledge base is up to date." | tee -a "$LOG_FILE"
  # Still update the last_updated date
  sed -i.tmp "s/^> last_updated:.*/> last_updated: $TODAY/" "$KB_FILE" && rm -f "$KB_FILE.tmp"
  echo "  Updated last_updated date to $TODAY." | tee -a "$LOG_FILE"
  exit 0
fi

# ── Inject new entries into the Recent Releases section ─────────────────────
echo "  Injecting new entries into knowledge base..." | tee -a "$LOG_FILE"

# Update last_updated date
sed -i.tmp "s/^> last_updated:.*/> last_updated: $TODAY/" "$KB_FILE" && rm -f "$KB_FILE.tmp"
sed -i.tmp "s/^> next_update:.*/> next_update: run scripts\/update-knowledge-base.sh/" "$KB_FILE" && rm -f "$KB_FILE.tmp"

# Insert new entries after the "Recent Releases" header line
INSERTION_LINE=$(grep -n "^## Recent Releases" "$KB_FILE" | head -1 | cut -d: -f1)
if [ -n "$INSERTION_LINE" ]; then
  INSERT_AT=$((INSERTION_LINE + 3))  # After the header and description line
  # Build temp file with insertion
  {
    head -n "$INSERT_AT" "$KB_FILE"
    echo ""
    echo "$NEW_FEATURES"
    echo ""
    tail -n "+$((INSERT_AT + 1))" "$KB_FILE"
  } > "$KB_FILE.new"
  mv "$KB_FILE.new" "$KB_FILE"
  echo "  New entries injected at line $INSERT_AT." | tee -a "$LOG_FILE"
else
  echo "  WARNING: Could not find insertion point. Appending to end." | tee -a "$LOG_FILE"
  echo "" >> "$KB_FILE"
  echo "---" >> "$KB_FILE"
  echo "" >> "$KB_FILE"
  echo "$NEW_FEATURES" >> "$KB_FILE"
fi

echo "[$TODAY] Knowledge base update complete." | tee -a "$LOG_FILE"
echo "  KB location: $KB_FILE" | tee -a "$LOG_FILE"
echo ""
echo "✅ Done. New entries added:"
echo "$NEW_FEATURES"
