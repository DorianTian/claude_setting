---
name: session-context
description: "Load full project context at session start — reads memory files, project docs, git history, and structure to present a concise situational briefing. Trigger: /session-context, 项目现状, 接上次, 继续"
disable-model-invocation: false
---

# Session Context Loader

Build situational awareness for a new session on whatever project you're currently in. Read all available context sources, synthesize, and present a concise briefing so the user can jump straight into work.

This skill is project-agnostic — it dynamically discovers what's available and adapts. Works for monorepos, single packages, polyglot projects, or bare repos.

## What to gather

Execute these in parallel where possible — speed matters, the user is waiting to start working.

### 1. Memory files

MEMORY.md is already in your conversation context (auto-loaded by Claude Code). For each file linked in MEMORY.md:
- Read the actual `.md` file (not just the index line)
- Categorize what you find:
  - **project** memories → active phases, decisions, pending work, deadlines
  - **feedback** memories → behavioral rules, preferences, things to avoid/repeat
  - **user** memories → role, expertise, working style
  - **reference** memories → external resources, dashboards, tracking systems

These memories are the most valuable context source — they capture what isn't in the code.

### 2. Project docs

Search for and read whichever of these exist (gracefully skip what's missing):
- `docs/TODO.md` or root `TODO.md` — task backlog and priorities
- `docs/` directory listing — planning, status, or architecture docs
- `CHANGELOG.md` or `HISTORY.md` — recent release notes
- Project-level `CLAUDE.md` or `AGENTS.md` — project-specific AI instructions
- `README.md` — project overview (skim the first ~50 lines for description, don't dump everything)

### 3. Git state

```bash
git log --oneline -15
git status --short
git branch --show-current
git stash list
```

This reveals: current branch, recent commit trail, uncommitted work, and stashed changes.

### 4. Project identity & structure

```bash
ls -la
```

Read the root config file — whichever exists:
- `package.json` (Node/JS/TS)
- `pyproject.toml` or `setup.py` (Python)
- `go.mod` (Go)
- `Cargo.toml` (Rust)
- `pom.xml` or `build.gradle` (Java)
- If none found, that's fine — it might be a scripts repo, docs repo, or bare workspace

Extract: project name, description, key dependencies, available scripts/commands.

If it's a monorepo (has `packages/`, `apps/`, or workspace config), also list workspace directories briefly.

## How to synthesize

After gathering everything, present a **concise briefing**. This is a handoff between past-you and present-you — include what matters for making decisions today, skip what's obvious from the code.

Adapt the structure to what you actually found. Skip sections with no content. Keep each section tight (3-5 lines max).

**Format:**

```
## [Project Name] — Session Context

**Branch**: <current> | **Status**: <clean/N files changed> | **Last commit**: <relative time + subject>

### Recent Progress
<Last ~5 meaningful commits, grouped by theme if related. Call out what was accomplished, not just commit messages.>

### Current Phase & Pending Tasks
<From TODO/memory. Order by priority. Mark what's done vs. what's next.>

### Key Context
<Important decisions, feedback rules, constraints, or active concerns from memory that should shape this session's work. Things the user told you to remember — behavioral rules, technical constraints, scope decisions.>

### Watch Out
<Anything stuck, failing, risky, or needing attention. Known bugs, blocked tasks, environment issues.>
```

End with a brief prompt asking what the user wants to tackle this session.

## Rules

- **Briefing, not report.** Concise and direct. Assume the user is a senior engineer.
- **Match the user's language.** Check memory for language preference. Default to the language of existing memory files and docs.
- **Surface decisions, not just facts.** "We chose X over Y because Z" is more useful than "X is configured."
- **Be honest about gaps.** If there's no TODO, no memory, or a fresh repo — say so briefly and ask what the user wants to focus on.
- **Don't read the entire codebase.** Only the context files listed above. The user will point you to specific code when needed.
- **Verify before claiming.** If a memory says "task X is blocked," check if recent commits may have resolved it. Memory can be stale.
- **Respect the user's style.** Follow any tone/format preferences from feedback memories or CLAUDE.md.
- **No project assumptions.** Don't assume TypeScript, don't assume monorepo, don't assume any specific framework. Discover, then adapt.
