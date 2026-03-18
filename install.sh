#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════
# claude-config — Claude Code Config Installer
# Usage:
#   claude-config                 Interactive mode
#   claude-config --all           Install all config files
#   claude-config --statusline    Install statusline only
#   claude-config --sync          Symlink Memory to iCloud
#   claude-config --knowledge     Symlink Knowledge to iCloud
#   claude-config --pull          Pull Memory & Knowledge from iCloud
#   claude-config --force         Overwrite without backup
#   claude-config --link          Register CLI command (~/.local/bin/claude-config)
#   Flags can be combined: claude-config --all --sync --knowledge
# ══════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# ── Parse flags ──
INSTALL_SETTINGS=false
INSTALL_STATUSLINE=false
INSTALL_CLAUDE_MD=false
SYNC=false
KNOWLEDGE=false
PULL=false
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
      --sync) SYNC=true ;;
      --knowledge) KNOWLEDGE=true ;;
      --pull) PULL=true ;;
      --force) FORCE=true ;;
      --link) LINK=true ;;
      --help|-h)
        echo "Usage: claude-config [options]"
        echo ""
        echo "Options:"
        echo "  (none)          Interactive mode"
        echo "  --all           Install all config files"
        echo "  --statusline    Install statusline only"
        echo "  --sync          Symlink Memory to iCloud"
        echo "  --knowledge     Symlink Knowledge to iCloud"
        echo "  --pull          Pull Memory & Knowledge from iCloud"
        echo "  --force         Overwrite without backup"
        echo "  --link          Register CLI command"
        echo "  --help          Show this help"
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
  echo "  Select components to install:"
  echo ""
  echo "  Config files:"
  echo "    1) settings.json     (deny rules + hooks + statusline + env)"
  echo "    2) statusline.sh     (dir + branch / model + context + cost)"
  echo "    3) CLAUDE.md         (global instructions)"
  echo "    4) All config files  (1 + 2 + 3)"
  echo ""
  echo "  iCloud sync:"
  echo "    5) Sync Memory       (symlink to iCloud)"
  echo "    6) Sync Knowledge    (symlink to iCloud)"
  echo "    7) Pull from iCloud  (one-time copy, no symlink)"
  echo ""
  echo "  Other:"
  echo "    8) Register CLI      (claude-config command)"
  echo "    9) Full setup        (all configs + iCloud sync + CLI)"
  echo ""
  printf "  Enter choices (e.g. 1 2 5, or 9 for full): "
  read -r choices

  for choice in $choices; do
    case "$choice" in
      1) INSTALL_SETTINGS=true ;;
      2) INSTALL_STATUSLINE=true ;;
      3) INSTALL_CLAUDE_MD=true ;;
      4) INSTALL_SETTINGS=true; INSTALL_STATUSLINE=true; INSTALL_CLAUDE_MD=true ;;
      5) SYNC=true ;;
      6) KNOWLEDGE=true ;;
      7) PULL=true ;;
      8) LINK=true ;;
      9) INSTALL_SETTINGS=true; INSTALL_STATUSLINE=true; INSTALL_CLAUDE_MD=true
         SYNC=true; KNOWLEDGE=true; LINK=true ;;
      *) echo "  ⚠ Unknown option: $choice" ;;
    esac
  done
  echo ""
fi

echo "══════════════════════════════════════════════════════════"
echo "  claude-config — Installing"
echo "══════════════════════════════════════════════════════════"

mkdir -p "$CLAUDE_DIR"

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
HAS_CONFIG=false
if [[ "$INSTALL_SETTINGS" == "true" || "$INSTALL_STATUSLINE" == "true" || "$INSTALL_CLAUDE_MD" == "true" ]]; then
  HAS_CONFIG=true
  echo ""
  echo "▶ Config files..."
  [[ "$INSTALL_SETTINGS" == "true" ]] && safe_install "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
  if [[ "$INSTALL_STATUSLINE" == "true" ]]; then
    safe_install "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh" "statusline.sh"
    chmod +x "$CLAUDE_DIR/statusline.sh"
  fi
  [[ "$INSTALL_CLAUDE_MD" == "true" ]] && safe_install "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"
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
ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
ICLOUD_MEMORY="$ICLOUD_DIR/claude-memory"
ICLOUD_KNOWLEDGE="$ICLOUD_DIR/Knowledge"
MEMORY_DIR_NAME="$(echo "$HOME" | tr '/' '-')"
MEMORY_PATH="$HOME/.claude/projects/$MEMORY_DIR_NAME/memory"

check_icloud() {
  if [[ ! -d "$ICLOUD_DIR" ]]; then
    echo "  ✗ iCloud Drive not found"
    echo "    Sign in to iCloud and enable iCloud Drive first."
    return 1
  fi
  return 0
}

# ── Sync Memory ──
if [[ "$SYNC" == "true" ]]; then
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

# ── Sync Knowledge ──
if [[ "$KNOWLEDGE" == "true" ]]; then
  echo ""
  echo "▶ Sync Knowledge → iCloud..."
  if check_icloud; then
    if [[ -L "$HOME/Knowledge" ]]; then
      echo "  = Knowledge (already symlinked)"
    elif [[ -d "$HOME/Knowledge" ]]; then
      mkdir -p "$ICLOUD_KNOWLEDGE"
      echo "  ↻ Moving to iCloud..."
      cp -r "$HOME/Knowledge/." "$ICLOUD_KNOWLEDGE/"
      rm -rf "$HOME/Knowledge"
      ln -s "$ICLOUD_KNOWLEDGE" "$HOME/Knowledge"
      echo "  ✓ Knowledge → iCloud Drive/Knowledge"
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

# ── Pull from iCloud ──
if [[ "$PULL" == "true" ]]; then
  echo ""
  echo "▶ Pull from iCloud (one-time copy)..."
  if check_icloud; then
    if [[ -L "$MEMORY_PATH" ]]; then
      echo "  ⚠ Memory is already symlinked, --pull not needed"
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

    if [[ -L "$HOME/Knowledge" ]]; then
      echo "  ⚠ Knowledge is already symlinked, --pull not needed"
    elif [[ -d "$ICLOUD_KNOWLEDGE" ]]; then
      mkdir -p "$HOME/Knowledge"
      cp -rn "$ICLOUD_KNOWLEDGE/." "$HOME/Knowledge/" 2>/dev/null || true
      echo "  ✓ Knowledge: pulled from iCloud"
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
[[ "$SYNC" == "true" ]] && ITEMS+=("Memory→iCloud")
[[ "$KNOWLEDGE" == "true" ]] && ITEMS+=("Knowledge→iCloud")
[[ "$PULL" == "true" ]] && ITEMS+=("iCloud→local")
[[ "$LINK" == "true" ]] && ITEMS+=("CLI:claude-config")

if [[ ${#ITEMS[@]} -eq 0 ]]; then
  echo "  Nothing selected. Run 'claude-config' for interactive mode."
else
  echo "  ✅ Done! $(IFS=', '; echo "${ITEMS[*]}")"
  echo "  Restart Claude Code to apply."
fi
echo "══════════════════════════════════════════════════════════"
