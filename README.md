# Claude Code Config

> Claude Code runtime configuration: settings, statusline, global instructions, and iCloud sync.

## Quick Start

```bash
git clone git@github.com:DorianTian/claude_setting.git claude-code-config
cd claude-code-config
./install.sh                        # Config files only
./install.sh --sync --knowledge     # Full setup with iCloud sync
```

## What's Included

| File | Installs to | Description |
|------|-------------|-------------|
| `settings.json` | `~/.claude/settings.json` | Permissions, deny rules, safety hooks, statusline, env tuning, plugins |
| `statusline.sh` | `~/.claude/statusline.sh` | 2-line status bar (directory + git branch / model + context + cost) |
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions: interaction rules, coding standards, AI-driven dev mode |

## Settings Highlights

- **Deny rules** — blocks access to `~/.ssh/`, `~/.aws/`, `~/.gnupg/`, `.env`, `credentials.json`, `*secret*`
- **Safety hooks** — intercepts `rm -rf /~/$HOME`, `git push --force main/master`, `DROP DATABASE/TABLE/SCHEMA`
- **StatusLine** — real-time display of directory, git branch, model, context usage (color-coded), cost, lines changed, duration, cache hit rate
- **Env tuning** — auto-compact at 75% context (default is ~95%), bash timeout config
- **Extended thinking** — always enabled
- **Session history** — 365 days retention (default is 30)

## StatusLine Preview

```
~/Desktop/workspace/my-project  main
Opus 4.6  1M 42% [████████░░░░░░░░░░░░]  $1.23  +156/-42  3m5s cache:37%
```

Context bar color: green (<50%) → yellow (<75%) → orange (<90%) → red (>90%)

## iCloud Sync

For syncing Memory and Knowledge across multiple Macs.

### Primary machine (real-time sync via symlink)

```bash
./install.sh --sync --knowledge
```

| Flag | What it does |
|------|-------------|
| `--sync` | Symlink `~/.claude/.../memory/` → `iCloud Drive/claude-memory/` |
| `--knowledge` | Symlink `~/Knowledge/` → `iCloud Drive/Knowledge/` |

### Secondary machine (one-time pull, no symlink)

```bash
./install.sh --pull
```

Copies Memory & Knowledge from iCloud to local directories. Smart merge: keeps the newer file when both sides have the same filename.

### No iCloud

```bash
./install.sh
```

Config files only. Memory and Knowledge stay local.

## install.sh Flags

| Flag | Description |
|------|-------------|
| (none) | Install config files only |
| `--sync` | Symlink Memory to iCloud |
| `--knowledge` | Symlink Knowledge to iCloud |
| `--pull` | One-time copy Memory & Knowledge from iCloud |
| `--force` | Overwrite without backup |

Flags can be combined: `./install.sh --sync --knowledge --force`

## Dependencies

- `jq` — required for statusline (install: `brew install jq`)
- `git` — required for statusline branch display

## Related Repos

| Repo | Description |
|------|-------------|
| [skills_repo](https://github.com/DorianTian/skills_repo) | Claude Code skills & plugins |
| [cursor_vscode_config](https://github.com/DorianTian/cursor_vscode_config) | IDE configuration (Cursor/VSCode/Neovim/formatters) |
