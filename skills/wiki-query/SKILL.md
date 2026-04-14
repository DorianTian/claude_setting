---
name: wiki-query
description: "Query the LLM Wiki knowledge base — multi-hop reasoning, confidence-aware, with citations. Optionally saves good answers back as wiki articles. Triggers: 查知识库, wiki query, 知识库查询"
user-invocable: true
---

# Wiki Query

Shortcut for `/wiki query`. Invoke the main wiki skill for the full workflow.

When triggered, use the Skill tool: `skill: "wiki", args: "query $ARGUMENTS"`
