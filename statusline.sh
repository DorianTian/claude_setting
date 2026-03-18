#!/bin/bash
# Claude Code Status Line - Dorian's Setup
# Line 1: directory + git branch
# Line 2: model | context% (color-coded bar) | cost | +lines/-lines | duration | cache%

set -euo pipefail

INPUT=$(cat)

# ── Parse fields ──
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "unknown"')
CONTEXT_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
LINES_ADDED=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
CONTEXT_SIZE=$(echo "$INPUT" | jq -r '.context_window.context_window_size // 200000')
CACHE_READ=$(echo "$INPUT" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
INPUT_TOKENS=$(echo "$INPUT" | jq -r '.context_window.current_usage.input_tokens // 0')
CURRENT_DIR=$(echo "$INPUT" | jq -r '.workspace.current_dir // ""')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.workspace.project_dir // ""')

# ── Git branch (cached 5s) ──
CACHE_FILE="/tmp/.claude_statusline_git_$$"
CACHE_TTL=5
GIT_BRANCH=""

get_git_branch() {
  local dir="${PROJECT_DIR:-$CURRENT_DIR}"
  if [ -n "$dir" ] && [ -d "$dir" ]; then
    GIT_BRANCH=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  fi
}

if [ -f "$CACHE_FILE" ]; then
  CACHE_AGE=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0) ))
  if [ "$CACHE_AGE" -lt "$CACHE_TTL" ]; then
    GIT_BRANCH=$(cat "$CACHE_FILE")
  else
    get_git_branch
    echo "$GIT_BRANCH" > "$CACHE_FILE"
  fi
else
  get_git_branch
  echo "$GIT_BRANCH" > "$CACHE_FILE"
fi

# ── Directory display (shorten home, show last 2 segments) ──
DISPLAY_DIR=""
if [ -n "$CURRENT_DIR" ]; then
  DISPLAY_DIR=$(echo "$CURRENT_DIR" | sed "s|^$HOME|~|")
fi

# ── Duration format ──
DURATION_SEC=$((DURATION_MS / 1000))
if [ "$DURATION_SEC" -ge 3600 ]; then
  DURATION="$((DURATION_SEC / 3600))h$((DURATION_SEC % 3600 / 60))m"
elif [ "$DURATION_SEC" -ge 60 ]; then
  DURATION="$((DURATION_SEC / 60))m$((DURATION_SEC % 60))s"
else
  DURATION="${DURATION_SEC}s"
fi

# ── Cost format ──
COST_FMT=$(printf '$%.2f' "$COST")

# ── Context window label ──
if [ "$CONTEXT_SIZE" -ge 1000000 ]; then
  CTX_LABEL="1M"
else
  CTX_LABEL="200K"
fi

# ── Context bar (20 chars) ──
BAR_WIDTH=20
CONTEXT_INT=${CONTEXT_PCT%.*}
CONTEXT_INT=${CONTEXT_INT:-0}
FILLED=$((CONTEXT_INT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))

# ── Colors ──
if [ "$CONTEXT_INT" -lt 50 ]; then
  COLOR="\033[32m"  # green
elif [ "$CONTEXT_INT" -lt 75 ]; then
  COLOR="\033[33m"  # yellow
elif [ "$CONTEXT_INT" -lt 90 ]; then
  COLOR="\033[38;5;208m"  # orange
else
  COLOR="\033[31m"  # red
fi
RESET="\033[0m"
DIM="\033[2m"
GREEN="\033[32m"
RED="\033[31m"
CYAN="\033[36m"
MAGENTA="\033[35m"

# ── Build bar ──
BAR=""
for ((i=0; i<FILLED; i++)); do BAR+="█"; done
for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

# ── Cache hit rate ──
CACHE_STR=""
if [ "$INPUT_TOKENS" -gt 0 ] 2>/dev/null; then
  TOTAL=$((CACHE_READ + INPUT_TOKENS))
  if [ "$TOTAL" -gt 0 ]; then
    CACHE_PCT=$((CACHE_READ * 100 / TOTAL))
    CACHE_STR="cache:${CACHE_PCT}%"
  fi
fi

# ── Line 1: directory + git branch ──
LINE1="${CYAN}${DISPLAY_DIR}${RESET}"
if [ -n "$GIT_BRANCH" ]; then
  LINE1="${LINE1} ${MAGENTA} ${GIT_BRANCH}${RESET}"
fi

# ── Line 2: model | context | cost | lines | duration | cache ──
LINE2="${DIM}${MODEL}${RESET} ${COLOR}${CTX_LABEL} ${CONTEXT_INT}% [${BAR}]${RESET} ${DIM}${COST_FMT}${RESET} ${GREEN}+${LINES_ADDED}${RESET}/${RED}-${LINES_REMOVED}${RESET} ${DIM}${DURATION} ${CACHE_STR}${RESET}"

printf "%b\n%b" "$LINE1" "$LINE2"
