---
name: wiki-init
description: "Initialize or retrofit a Karpathy-style LLM Wiki in any directory. Scans existing content, generates schema.md (taxonomy + conventions), index.md (article catalog), log.md (operation log), and raw/ directory. Works on empty dirs or existing knowledge bases. Triggers: wiki init, 初始化知识库, init wiki, bootstrap wiki"
user-invocable: true
---

# Wiki Init

Shortcut for `/wiki init`. Invoke the main wiki skill for the full workflow.

When triggered, use the Skill tool: `skill: "wiki", args: "init $ARGUMENTS"`
