#!/bin/bash
# Stop hook: Memory check triggered by new git commits
# Only fires when new commits have been made since last check
# State file stores the last-seen commit hash

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

# State tracking — stores last-seen commit hash
state_dir="/tmp/claude"
mkdir -p "$state_dir" 2>/dev/null
state_file="${state_dir}/memcheck-${session_id}"

# Must be in a git repo
[ -z "$cwd" ] && exit 0
current_hash=$(git -C "$cwd" rev-parse HEAD 2>/dev/null) || exit 0

# Read last-seen commit hash (validate it looks like a hex hash)
last_hash=""
if [ -f "$state_file" ]; then
  raw=$(cat "$state_file" 2>/dev/null | tr -d ' \n')
  # Only accept 7+ hex chars — reject stale turn-count values from old format
  if echo "$raw" | grep -qE '^[0-9a-f]{7,}$'; then
    last_hash="$raw"
  fi
fi

# No new commits since last check — skip
[ "$current_hash" = "$last_hash" ] && exit 0

# First run or invalid state — record current hash, don't trigger
if [ -z "$last_hash" ]; then
  echo "$current_hash" > "$state_file"
  exit 0
fi

# New commit(s) detected — count how many
new_commits=$(git -C "$cwd" rev-list --count "${last_hash}..${current_hash}" 2>/dev/null || echo "?")

# Update state
echo "$current_hash" > "$state_file"

cat >&2 <<HOOKEOF
New commits detected (${new_commits} since last check). Time for a memory check:

1. SESSION SUMMARY: Update or create session memory (type: project, file: session_YYYY-MM-DD_<topic>.md). Include: date, topic, key decisions, changes implemented, open items. Keep it under 20 lines.

2. MEMORY CHECK: Any reusable learnings — user feedback, technical decisions, project context changes? Save as separate memory files with confidence scores. Skip if nothing new.
HOOKEOF
exit 2
