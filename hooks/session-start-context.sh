#!/bin/bash
# SessionStart hook: Auto-trigger session-context in git project directories
# Only fires on fresh startup (not resume/clear/compact)
# Only fires in git project directories (not home dir quick Q&A)

input=$(cat)
trigger=$(echo "$input" | jq -r '.trigger // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

# Only on fresh startup
[ "$trigger" != "startup" ] && exit 0

# Must be in a git project directory
[ -z "$cwd" ] && exit 0
[ ! -d "$cwd/.git" ] && exit 0

# Skip home directory itself (quick Q&A sessions)
[ "$cwd" = "$HOME" ] && exit 0

# Inject context telling Claude to auto-load session context
echo "Auto session-context: You are in a git project directory. Invoke the session-context skill to load project context before responding to the user's first message."
exit 0
