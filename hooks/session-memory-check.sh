#!/bin/bash
# Stop hook: Block stop on substantial sessions to enforce memory check
# Fires once per session — first Stop blocked, second Stop allowed
# Only triggers on sessions with 20+ transcript lines

input=$(cat)
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# State tracking — ensure one-time firing per session
state_dir="/tmp/claude"
mkdir -p "$state_dir" 2>/dev/null
state_file="${state_dir}/memcheck-${session_id}"

# Already fired this session — let stop proceed
[ -f "$state_file" ] && exit 0

# No transcript available
[ -z "$transcript_path" ] || [ ! -f "$transcript_path" ] && exit 0

# Count transcript lines — skip trivial sessions
line_count=$(wc -l < "$transcript_path" 2>/dev/null | tr -d ' ')
[ "$line_count" -lt 20 ] && exit 0

# Mark as done so next Stop goes through
touch "$state_file"

# Block stop — force session summary + memory check
cat >&2 <<HOOKEOF
Session wrap-up required (${line_count} lines). You MUST do both before ending:

1. SESSION SUMMARY: Write a brief session summary to memory (type: project, file: session_YYYY-MM-DD_<topic>.md). Include: date, topic, key decisions made, changes implemented, open items if any. Keep it under 20 lines.

2. MEMORY CHECK: Review for reusable learnings — user feedback, technical decisions with rationale, project context changes. Save as separate memory files with confidence scores. Skip if routine Q&A with no new learnings.
HOOKEOF
exit 2
