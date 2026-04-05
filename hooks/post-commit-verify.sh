#!/bin/bash
# PostToolUse hook: Verify after git commit
# Injects reminder to check commit result and run tests if applicable

command=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.command // empty')

if echo "$command" | grep -qE 'git\s+commit'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"Git commit executed. Verify: (1) git log --oneline -1 confirms correct message (2) git diff HEAD confirms no unintended changes left (3) run project tests if available."}}'
fi

exit 0
