# Claude Code Config

> Claude Code runtime configuration: settings, statusline, global instructions, and iCloud sync.

## Quick Start

```bash
git clone git@github.com:DorianTian/claude_setting.git ~/Desktop/workspace/claude-code-config
cd ~/Desktop/workspace/claude-code-config
./install.sh              # Interactive mode
./install.sh --all        # Non-interactive: install all config files
./install.sh --link       # Register CLI command
```

After `--link`, you can use `claude-config` from anywhere:

```bash
claude-config             # Interactive menu
claude-config --all --sync --knowledge   # Full setup
```

## New Machine Setup

```bash
# 1. Clone
git clone git@github.com:DorianTian/claude_setting.git ~/Desktop/workspace/claude-code-config
cd ~/Desktop/workspace/claude-code-config

# 2. Interactive install (select what you need)
./install.sh

# 3. Register CLI command (optional, select option 8 in interactive menu or:)
./install.sh --link

# Requires ~/.local/bin in PATH. If not, add to ~/.zshrc:
#   export PATH="$HOME/.local/bin:$PATH"
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

## CLI Usage

```bash
claude-config                 # Interactive menu
claude-config --all           # Install all config files
claude-config --statusline    # Install statusline only
claude-config --sync          # Symlink Memory to iCloud
claude-config --knowledge     # Symlink Knowledge to iCloud
claude-config --pull          # One-time copy from iCloud
claude-config --force         # Overwrite without backup
claude-config --link          # Register CLI command
claude-config --help          # Show help
```

Flags can be combined: `claude-config --all --sync --knowledge`

## iCloud Sync

For syncing Memory and Knowledge across multiple Macs.

### Primary machine (real-time sync via symlink)

```bash
claude-config --sync --knowledge
```

| Flag | What it does |
|------|-------------|
| `--sync` | Symlink `~/.claude/.../memory/` → `iCloud Drive/claude-memory/` |
| `--knowledge` | Symlink `~/Knowledge/` → `iCloud Drive/Knowledge/` |

### Secondary machine (one-time pull, no symlink)

```bash
claude-config --pull
```

Copies Memory & Knowledge from iCloud to local directories. Smart merge: keeps the newer file when both sides have the same filename.

### No iCloud

```bash
claude-config --all
```

Config files only. Memory and Knowledge stay local.

## Dependencies

- `jq` — required for statusline (install: `brew install jq`)
- `git` — required for statusline branch display

## Related Repos

| Repo | CLI Command | Description |
|------|-------------|-------------|
| [skills_repo](https://github.com/DorianTian/skills_repo) | `claude-skills` | Claude Code skills & plugins |
| [cursor_vscode_config](https://github.com/DorianTian/cursor_vscode_config) | `ide-config` | IDE configuration (Cursor/VSCode/Neovim/Ghostty/Zsh/formatters) |
