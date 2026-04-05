#!/bin/bash
# PreToolUse hook: Scan Write/Edit content for hardcoded credentials
# Exit 2 = block, Exit 0 = allow

content=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.content // .new_string // empty')

if [ -z "$content" ]; then
  exit 0
fi

# AWS Access Keys
if echo "$content" | grep -qE 'AKIA[0-9A-Z]{16}'; then
  echo "BLOCK: AWS Access Key detected in content." >&2
  exit 2
fi

# GitHub tokens (PAT, fine-grained)
if echo "$content" | grep -qE 'gh[ps]_[A-Za-z0-9_]{36,}'; then
  echo "BLOCK: GitHub token detected in content." >&2
  exit 2
fi

# OpenAI / Anthropic API keys
if echo "$content" | grep -qE 'sk-[A-Za-z0-9]{20,}'; then
  echo "BLOCK: API key (OpenAI/Anthropic pattern) detected in content." >&2
  exit 2
fi

# Private keys
if echo "$content" | grep -q 'BEGIN.*PRIVATE KEY'; then
  echo "BLOCK: Private key detected in content." >&2
  exit 2
fi

# Generic high-entropy credentials (api_key = "...", password = "...")
if echo "$content" | grep -qE '(api[_-]?key|api_token|password|auth_token)[[:space:]]*[:=][[:space:]]*["\x27][A-Za-z0-9+/=]{32,}'; then
  echo "BLOCK: Potential hardcoded credential detected in content." >&2
  exit 2
fi

exit 0
