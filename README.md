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
claude-config --all --memory --knowledge  # Full setup
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
| `CLAUDE.md` | `~/.claude/CLAUDE.md` → iCloud | Global instructions (lives in iCloud, symlinked on install) |

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
claude-config                    # Interactive menu
claude-config --all              # Install all config files
claude-config --statusline       # Install statusline only
claude-config --knowledge        # Symlink Knowledge to iCloud
claude-config --ai-daily         # Symlink AI-Daily to iCloud
claude-config --link             # Register CLI command
claude-config --help             # Show help
```

Flags can be combined: `claude-config --all --knowledge --ai-daily`

## iCloud Sync

All machines use symlink to iCloud, script never writes to iCloud.

**CLAUDE.md** lives in `iCloud Drive/claude-memory/CLAUDE.md` and is symlinked on all machines. `--all` handles this automatically — no separate flag needed.

```bash
claude-config --all --knowledge --ai-daily
```

| What | Symlink |
|------|---------|
| CLAUDE.md | `~/.claude/CLAUDE.md` → `iCloud Drive/claude-memory/CLAUDE.md` |
| Knowledge | `~/Knowledge/` → `iCloud Drive/Knowledge/` |
| AI-Daily | `~/AI-Daily/` → `iCloud Drive/AI-Daily/` |

Local conflicts are overwritten directly — iCloud is source of truth, script never writes to iCloud.

## AI Daily Digest

每日自动抓取 AI 资讯（HN + GitHub Trending + ArXiv），存储在 iCloud Drive 多端同步。

```bash
# 手动抓取
node ~/Desktop/workspace/claude-code-config/scripts/ai-daily.mjs

# 主力机自动抓取（crontab，每天 9:07 AM）
# 7 9 * * * /opt/homebrew/bin/node ~/Desktop/workspace/claude-code-config/scripts/ai-daily.mjs >> ~/AI-Daily/cron.log 2>&1

# 其他 Mac 只需 symlink
claude-config --ai-daily
```

每天生成两份文件：`.md`（完整链接）+ `.txt`（纯文本快速阅读）。

## Dependencies

- `jq` — required for statusline (install: `brew install jq`)
- `git` — required for statusline branch display

## Related Repos

| Repo | CLI Command | Description |
|------|-------------|-------------|
| [skills_repo](https://github.com/DorianTian/skills_repo) | `claude-skills` | Claude Code skills & plugins |
| [cursor_vscode_config](https://github.com/DorianTian/cursor_vscode_config) | `ide-config` | IDE configuration (Cursor/VSCode/Neovim/Ghostty/Zsh/formatters) |
