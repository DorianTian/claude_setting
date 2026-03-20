#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════
# claude-config — Claude Code Config Installer
# Usage:
#   claude-config                    Interactive mode
#   claude-config --all              Install all config files
#   claude-config --statusline       Install statusline only
#   claude-config --memory           Symlink Memory to iCloud
#   claude-config --knowledge        Symlink Knowledge to iCloud
#   claude-config --pull-memory      Pull Memory from iCloud (one-time copy)
#   claude-config --pull-knowledge   Pull Knowledge from iCloud (one-time copy)
#   claude-config --force            Overwrite config files without creating .bak backup
#   claude-config --link             Register CLI command (~/.local/bin/claude-config)
#   Flags can be combined: claude-config --all --memory --knowledge
# ══════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# ── Parse flags ──
INSTALL_SETTINGS=false
INSTALL_STATUSLINE=false
INSTALL_CLAUDE_MD=false
MEMORY=false
KNOWLEDGE=false
PULL_MEMORY=false
PULL_KNOWLEDGE=false
FORCE=false
LINK=false
INTERACTIVE=false

if [[ $# -eq 0 ]]; then
  INTERACTIVE=true
else
  for arg in "$@"; do
    case "$arg" in
      --all) INSTALL_SETTINGS=true; INSTALL_STATUSLINE=true; INSTALL_CLAUDE_MD=true ;;
      --statusline) INSTALL_STATUSLINE=true ;;
      --memory) MEMORY=true ;;
      --knowledge) KNOWLEDGE=true ;;
      --pull-memory) PULL_MEMORY=true ;;
      --pull-knowledge) PULL_KNOWLEDGE=true ;;
      --force) FORCE=true ;;
      --link) LINK=true ;;
      --help|-h)
        echo "Usage: claude-config [options]"
        echo ""
        echo "  Config files:"
        echo "    (none)            Interactive mode"
        echo "    --all             Install all config files (settings + statusline + CLAUDE.md)"
        echo "    --statusline      Install statusline only"
        echo ""
        echo "  iCloud sync (symlink, real-time):"
        echo "    --memory          Symlink Memory to iCloud"
        echo "    --knowledge       Symlink Knowledge to iCloud"
        echo ""
        echo "  iCloud pull (one-time copy, no symlink):"
        echo "    --pull-memory     Pull Memory from iCloud"
        echo "    --pull-knowledge  Pull Knowledge from iCloud"
        echo ""
        echo "  Other:"
        echo "    --force           Overwrite config files without creating .bak backup"
        echo "    --link            Register 'claude-config' CLI command"
        echo "    --help            Show this help"
        echo ""
        echo "  Flags can be combined: claude-config --all --memory --knowledge"
        exit 0
        ;;
    esac
  done
fi

# ── Interactive menu ──
if [[ "$INTERACTIVE" == "true" ]]; then
  echo "══════════════════════════════════════════════════════════"
  echo "  claude-config — Claude Code Config Installer"
  echo "══════════════════════════════════════════════════════════"
  echo ""
  echo "  Config files:"
  echo "    1) settings.json       (deny rules + hooks + statusline + env)"
  echo "    2) statusline.sh       (dir + branch / model + context + cost)"
  echo "    3) CLAUDE.md           (global instructions)"
  echo "    4) All config files    (1 + 2 + 3)"
  echo ""
  echo "  iCloud sync (symlink, real-time):"
  echo "    5) Sync Memory         → iCloud"
  echo "    6) Sync Knowledge      → iCloud"
  echo ""
  echo "  iCloud pull (one-time copy, no symlink):"
  echo "    7) Pull Memory         ← iCloud"
  echo "    8) Pull Knowledge      ← iCloud"
  echo ""
  echo "  Other:"
  echo "    9) Register CLI        (claude-config command)"
  echo "    0) Full setup          (all configs + sync Memory & Knowledge + CLI)"
  echo ""
  printf "  Enter choices (e.g. 1 2 5, or 0 for full): "
  read -r choices

  for choice in $choices; do
    case "$choice" in
      1) INSTALL_SETTINGS=true ;;
      2) INSTALL_STATUSLINE=true ;;
      3) INSTALL_CLAUDE_MD=true ;;
      4) INSTALL_SETTINGS=true; INSTALL_STATUSLINE=true; INSTALL_CLAUDE_MD=true ;;
      5) SYNC=true ;;
      6) KNOWLEDGE=true ;;
      7) PULL_MEMORY=true ;;
      8) PULL_KNOWLEDGE=true ;;
      9) LINK=true ;;
      0) INSTALL_SETTINGS=true; INSTALL_STATUSLINE=true; INSTALL_CLAUDE_MD=true
         MEMORY=true; KNOWLEDGE=true; LINK=true ;;
      *) echo "  ⚠ Unknown option: $choice" ;;
    esac
  done
  echo ""
fi

echo "══════════════════════════════════════════════════════════"
echo "  claude-config — Installing"
echo "══════════════════════════════════════════════════════════"

mkdir -p "$CLAUDE_DIR"

# ── iCloud paths (used by config install + sync sections) ──
ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
ICLOUD_MEMORY="$ICLOUD_DIR/claude-memory"
ICLOUD_KNOWLEDGE="$ICLOUD_DIR/Knowledge"
MEMORY_DIR_NAME="$(echo "$HOME" | tr '/' '-')"
MEMORY_PATH="$HOME/.claude/projects/$MEMORY_DIR_NAME/memory"

# ── Helper: safe copy with backup ──
safe_install() {
  local src="$1" dst="$2" name="$3"
  if [[ -f "$dst" && "$FORCE" != "true" ]]; then
    if diff -q "$src" "$dst" &>/dev/null; then
      echo "  = $name (unchanged)"
      return
    fi
    cp "$dst" "${dst}.bak"
    echo "  ↻ $name (backed up → $(basename "$dst").bak)"
  else
    echo "  + $name"
  fi
  cp "$src" "$dst"
}

# ── Config files ──
if [[ "$INSTALL_SETTINGS" == "true" || "$INSTALL_STATUSLINE" == "true" || "$INSTALL_CLAUDE_MD" == "true" ]]; then
  echo ""
  echo "▶ Config files..."
  [[ "$INSTALL_SETTINGS" == "true" ]] && safe_install "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
  if [[ "$INSTALL_STATUSLINE" == "true" ]]; then
    safe_install "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh" "statusline.sh"
    chmod +x "$CLAUDE_DIR/statusline.sh"
  fi
  if [[ "$INSTALL_CLAUDE_MD" == "true" ]]; then
    ICLOUD_CLAUDE_MD="$ICLOUD_DIR/claude-memory/CLAUDE.md"
    if [[ -L "$CLAUDE_DIR/CLAUDE.md" ]]; then
      echo "  = CLAUDE.md (already symlinked)"
    elif [[ -f "$ICLOUD_CLAUDE_MD" ]]; then
      [[ -f "$CLAUDE_DIR/CLAUDE.md" && "$FORCE" != "true" ]] && cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
      ln -sf "$ICLOUD_CLAUDE_MD" "$CLAUDE_DIR/CLAUDE.md"
      echo "  ✓ CLAUDE.md → iCloud Drive/claude-memory/CLAUDE.md"
    else
      echo "  ✗ CLAUDE.md not found in iCloud (expected: $ICLOUD_CLAUDE_MD)"
      echo "    Copy your CLAUDE.md to iCloud first, then re-run."
    fi
  fi
fi

# ── Dependency check (only if statusline involved) ──
if [[ "$INSTALL_STATUSLINE" == "true" ]]; then
  echo ""
  echo "▶ Dependencies..."
  command -v jq &>/dev/null && echo "  ✓ jq $(jq --version 2>&1)" || echo "  ✗ jq not found — brew install jq"
  command -v git &>/dev/null && echo "  ✓ git $(git --version | awk '{print $3}')" || echo "  ✗ git not found"

  echo ""
  echo "▶ Testing statusline..."
  TEST_OUTPUT=$(echo '{"model":{"display_name":"Test"},"context_window":{"used_percentage":25,"context_window_size":1000000,"current_usage":{"input_tokens":1000,"cache_read_input_tokens":500}},"cost":{"total_cost_usd":0.5,"total_lines_added":10,"total_lines_removed":3,"total_duration_ms":60000},"workspace":{"current_dir":"'"$HOME"'","project_dir":""}}' | "$CLAUDE_DIR/statusline.sh" 2>&1) && echo "  ✓ Statusline works" || echo "  ✗ Statusline failed: $TEST_OUTPUT"
fi

# ── iCloud helpers ──
check_icloud() {
  if [[ ! -d "$ICLOUD_DIR" ]]; then
    echo "  ✗ iCloud Drive not found"
    echo "    Sign in to iCloud and enable iCloud Drive first."
    return 1
  fi
  return 0
}

# ── Sync Memory (symlink) ──
if [[ "$MEMORY" == "true" ]]; then
  echo ""
  echo "▶ Sync Memory → iCloud..."
  if check_icloud; then
    if [[ -L "$MEMORY_PATH" ]]; then
      echo "  = Memory (already symlinked)"
    else
      mkdir -p "$ICLOUD_MEMORY"
      if [[ -d "$MEMORY_PATH" ]]; then
        echo "  ↻ Merging local → iCloud..."
        for f in "$MEMORY_PATH"/*; do
          [[ -f "$f" ]] || continue
          fname="$(basename "$f")"
          if [[ -f "$ICLOUD_MEMORY/$fname" ]]; then
            if [[ "$f" -nt "$ICLOUD_MEMORY/$fname" ]]; then
              cp "$f" "$ICLOUD_MEMORY/$fname"
              echo "    ↻ $fname (local is newer)"
            else
              echo "    = $fname (iCloud is newer, kept)"
            fi
          else
            cp "$f" "$ICLOUD_MEMORY/$fname"
            echo "    + $fname"
          fi
        done
        rm -rf "$MEMORY_PATH"
      fi
      mkdir -p "$(dirname "$MEMORY_PATH")"
      ln -s "$ICLOUD_MEMORY" "$MEMORY_PATH"
      echo "  ✓ Memory → iCloud Drive/claude-memory"
    fi
  fi
fi

# ── Sync Knowledge (symlink) ──
if [[ "$KNOWLEDGE" == "true" ]]; then
  echo ""
  echo "▶ Sync Knowledge → iCloud..."
  if check_icloud; then
    if [[ -L "$HOME/Knowledge" ]]; then
      echo "  = Knowledge (already symlinked)"
    elif [[ -d "$HOME/Knowledge" ]]; then
      mkdir -p "$ICLOUD_KNOWLEDGE"
      echo "  ↻ Merging (iCloud wins on conflicts)..."
      # 1. 本地有、iCloud 没有的文件 → 补到 iCloud（-n = no overwrite）
      cp -rn "$HOME/Knowledge/." "$ICLOUD_KNOWLEDGE/" 2>/dev/null || true
      # 2. 删除本地目录，建 symlink 指向 iCloud（iCloud 内容为准）
      rm -rf "$HOME/Knowledge"
      ln -s "$ICLOUD_KNOWLEDGE" "$HOME/Knowledge"
      echo "  ✓ Knowledge → iCloud Drive/Knowledge (iCloud is source of truth)"
    else
      if [[ -d "$ICLOUD_KNOWLEDGE" ]]; then
        ln -s "$ICLOUD_KNOWLEDGE" "$HOME/Knowledge"
        echo "  ✓ Knowledge → iCloud Drive/Knowledge"
      else
        echo "  - No Knowledge found locally or in iCloud"
      fi
    fi
  fi
fi

# ── Pull Memory (one-time copy) ──
if [[ "$PULL_MEMORY" == "true" ]]; then
  echo ""
  echo "▶ Pull Memory ← iCloud..."
  if check_icloud; then
    if [[ -L "$MEMORY_PATH" ]]; then
      echo "  ⚠ Memory is already symlinked, pull not needed"
    elif [[ -d "$ICLOUD_MEMORY" ]]; then
      mkdir -p "$MEMORY_PATH"
      PULLED=0; SKIPPED=0
      for f in "$ICLOUD_MEMORY"/*; do
        [[ -f "$f" ]] || continue
        fname="$(basename "$f")"
        if [[ -f "$MEMORY_PATH/$fname" ]]; then
          if [[ "$f" -nt "$MEMORY_PATH/$fname" ]]; then
            cp "$f" "$MEMORY_PATH/$fname"
            echo "    ↻ $fname (iCloud is newer)"
            ((PULLED++))
          else
            ((SKIPPED++))
          fi
        else
          cp "$f" "$MEMORY_PATH/$fname"
          echo "    + $fname"
          ((PULLED++))
        fi
      done
      echo "  ✓ Memory: pulled $PULLED, skipped $SKIPPED"
    else
      echo "  - No iCloud memory found"
    fi
  fi
fi

# ── Pull Knowledge (one-time copy) ──
if [[ "$PULL_KNOWLEDGE" == "true" ]]; then
  echo ""
  echo "▶ Pull Knowledge ← iCloud..."
  if check_icloud; then
    if [[ -L "$HOME/Knowledge" ]]; then
      echo "  ⚠ Knowledge is already symlinked, pull not needed"
    elif [[ -d "$ICLOUD_KNOWLEDGE" ]]; then
      mkdir -p "$HOME/Knowledge"
      cp -rn "$ICLOUD_KNOWLEDGE/." "$HOME/Knowledge/" 2>/dev/null || true
      echo "  ✓ Knowledge: pulled from iCloud (new files only, no overwrite)"
    else
      echo "  - No iCloud Knowledge found"
    fi
  fi
fi

# ── Register CLI command ──
if [[ "$LINK" == "true" ]]; then
  echo ""
  echo "▶ Registering CLI command..."
  mkdir -p "$HOME/.local/bin"
  ln -sf "$SCRIPT_DIR/install.sh" "$HOME/.local/bin/claude-config"
  echo "  ✓ claude-config → $SCRIPT_DIR/install.sh"
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "  ⚠ ~/.local/bin is not in PATH. Add to ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
fi

# ── Summary ──
echo ""
echo "══════════════════════════════════════════════════════════"
ITEMS=()
[[ "$INSTALL_SETTINGS" == "true" ]] && ITEMS+=("settings.json")
[[ "$INSTALL_STATUSLINE" == "true" ]] && ITEMS+=("statusline.sh")
[[ "$INSTALL_CLAUDE_MD" == "true" ]] && ITEMS+=("CLAUDE.md")
[[ "$MEMORY" == "true" ]] && ITEMS+=("Memory→iCloud")
[[ "$KNOWLEDGE" == "true" ]] && ITEMS+=("Knowledge→iCloud")
[[ "$PULL_MEMORY" == "true" ]] && ITEMS+=("Memory←iCloud")
[[ "$PULL_KNOWLEDGE" == "true" ]] && ITEMS+=("Knowledge←iCloud")
[[ "$LINK" == "true" ]] && ITEMS+=("CLI:claude-config")

if [[ ${#ITEMS[@]} -eq 0 ]]; then
  echo "  Nothing selected. Run 'claude-config' for interactive mode."
else
  echo "  ✅ Done! $(IFS=', '; echo "${ITEMS[*]}")"
  echo "  Restart Claude Code to apply."
fi
echo "══════════════════════════════════════════════════════════"
