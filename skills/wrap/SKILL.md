---
name: wrap
description: "Manual session wrap-up — save session summary and check for reusable learnings to memory. Trigger: /wrap, 收尾, 记一下, save session, wrap up"
---

# Session Wrap-up

Manually triggered memory checkpoint. Do both steps below, then confirm to the user what was saved.

## Step 1: Session Summary

Write or update a session summary memory file:

- **File**: `session_YYYY-MM-DD_<topic>.md` (use today's date and a short topic slug)
- **Type**: `project`
- **Content**: date, topic, key decisions made, changes implemented, open items
- **Max 20 lines** — this is a checkpoint, not a report

If a session summary for today's topic already exists, update it rather than creating a duplicate.

## Step 2: Memory Check

Scan the conversation for reusable learnings worth persisting across sessions:

- **User feedback or preferences** (type: `feedback`) — corrections, confirmed approaches, style preferences
- **Technical decisions with rationale** (type: `project`) — why X was chosen over Y, constraints discovered
- **Project context changes** (type: `project`) — status updates, phase transitions, blockers resolved
- **External references** (type: `reference`) — dashboards, docs, tracking systems mentioned

For each new learning:
- Save as a separate memory file with `confidence: 0.7` (or higher if confirmed by user)
- Check MEMORY.md first — update existing entries rather than creating duplicates
- Skip if the information is already captured or is routine Q&A with no new insight

## Rules

- Don't save things derivable from code or git history
- Don't save ephemeral task details only relevant to this conversation
- Update MEMORY.md index after writing any new files
- Be brief in confirming to the user — just list what was saved, no ceremony
