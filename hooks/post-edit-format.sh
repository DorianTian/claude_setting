#!/bin/bash
# PostToolUse hook: Remind to format after code file edits
# Outputs additionalContext JSON for code files, silent for non-code files

file_path=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty')

if [ -z "$file_path" ]; then
  exit 0
fi

if echo "$file_path" | grep -qE '\.(ts|tsx|js|jsx|go|py|css|scss)$'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"Code file modified. Run formatter before committing."}}'
fi

exit 0
