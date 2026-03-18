#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════
# Claude Code Config Installer
# Usage:
#   ./install.sh            Install config files only
#   ./install.sh --sync     Sync Memory & Knowledge to iCloud (symlink, real-time sync)
#   ./install.sh --pull     Pull Memory & Knowledge from iCloud (one-time copy, no symlink)
#   ./install.sh --force    Overwrite without backup
# ══════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SYNC=false
PULL=false
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --sync) SYNC=true ;;
    --pull) PULL=true ;;
    --force) FORCE=true ;;
  esac
done

echo "══════════════════════════════════════════════════════════"
echo "  Claude Code Config Installer"
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

# ── Step 1: Config files ──
echo ""
echo "▶ Step 1: Installing config files..."
safe_install "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
safe_install "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh" "statusline.sh"
chmod +x "$CLAUDE_DIR/statusline.sh"
safe_install "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"

# ── Step 2: Verify dependencies ──
echo ""
echo "▶ Step 2: Checking dependencies..."
if command -v jq &>/dev/null; then
  echo "  ✓ jq $(jq --version 2>&1)"
else
  echo "  ✗ jq not found (required for statusline)"
  echo "    Install: brew install jq"
fi

if command -v git &>/dev/null; then
  echo "  ✓ git $(git --version | awk '{print $3}')"
else
  echo "  ✗ git not found (required for statusline branch display)"
fi

# ── Step 3: Test statusline ──
echo ""
echo "▶ Step 3: Testing statusline..."
TEST_OUTPUT=$(echo '{"model":{"display_name":"Test"},"context_window":{"used_percentage":25,"context_window_size":1000000,"current_usage":{"input_tokens":1000,"cache_read_input_tokens":500}},"cost":{"total_cost_usd":0.5,"total_lines_added":10,"total_lines_removed":3,"total_duration_ms":60000},"workspace":{"current_dir":"'"$HOME"'","project_dir":""}}' | "$CLAUDE_DIR/statusline.sh" 2>&1) && echo "  ✓ Statusline works" || echo "  ✗ Statusline failed: $TEST_OUTPUT"

# ── Step 4: iCloud sync (only with --sync) ──
if [[ "$SYNC" == "true" ]]; then
  echo ""
  echo "▶ Step 4: iCloud sync..."

  ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

  if [[ ! -d "$ICLOUD_DIR" ]]; then
    echo "  ✗ iCloud Drive not found, skipping"
    echo "    Sign in to iCloud and enable iCloud Drive first."
  else
    # ── Memory ──
    MEMORY_DIR_NAME="$(echo "$HOME" | tr '/' '-')"
    MEMORY_PATH="$HOME/.claude/projects/$MEMORY_DIR_NAME/memory"
    ICLOUD_MEMORY="$ICLOUD_DIR/claude-memory"

    if [[ -L "$MEMORY_PATH" ]]; then
      echo "  = Memory (already symlinked)"
    else
      mkdir -p "$ICLOUD_MEMORY"
      if [[ -d "$MEMORY_PATH" ]]; then
        echo "  ↻ Memory: copying local files to iCloud..."
        # Copy local files to iCloud (won't overwrite existing newer files)
        for f in "$MEMORY_PATH"/*; do
          fname="$(basename "$f")"
          if [[ -f "$ICLOUD_MEMORY/$fname" ]]; then
            # iCloud already has this file — keep the newer one
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

    # ── Knowledge ──
    ICLOUD_KNOWLEDGE="$ICLOUD_DIR/Knowledge"

    if [[ -L "$HOME/Knowledge" ]]; then
      echo "  = Knowledge (already symlinked)"
    elif [[ -d "$HOME/Knowledge" ]]; then
      mkdir -p "$ICLOUD_KNOWLEDGE"
      echo "  ↻ Knowledge: moving to iCloud..."
      cp -r "$HOME/Knowledge/." "$ICLOUD_KNOWLEDGE/"
      rm -rf "$HOME/Knowledge"
      ln -s "$ICLOUD_KNOWLEDGE" "$HOME/Knowledge"
      echo "  ✓ Knowledge → iCloud Drive/Knowledge"
    else
      echo "  - Knowledge: ~/Knowledge not found, skipping"
    fi
  fi
elif [[ "$PULL" == "true" ]]; then
  echo ""
  echo "▶ Step 4: Pull from iCloud (one-time copy, no symlink)..."

  ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

  if [[ ! -d "$ICLOUD_DIR" ]]; then
    echo "  ✗ iCloud Drive not found"
    echo "    Sign in to iCloud and enable iCloud Drive first."
  else
    # ── Pull Memory ──
    MEMORY_DIR_NAME="$(echo "$HOME" | tr '/' '-')"
    MEMORY_PATH="$HOME/.claude/projects/$MEMORY_DIR_NAME/memory"
    ICLOUD_MEMORY="$ICLOUD_DIR/claude-memory"

    if [[ -d "$ICLOUD_MEMORY" ]]; then
      mkdir -p "$MEMORY_PATH"
      PULLED=0
      SKIPPED=0
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
      echo "  ✓ Memory: pulled $PULLED files, skipped $SKIPPED (local is newer or same)"
    else
      echo "  - No iCloud memory found (iCloud Drive/claude-memory)"
    fi

    # ── Pull Knowledge ──
    ICLOUD_KNOWLEDGE="$ICLOUD_DIR/Knowledge"

    if [[ -d "$ICLOUD_KNOWLEDGE" ]]; then
      mkdir -p "$HOME/Knowledge"
      cp -rn "$ICLOUD_KNOWLEDGE/." "$HOME/Knowledge/" 2>/dev/null || true
      echo "  ✓ Knowledge: pulled from iCloud (new files only, no overwrite)"
    else
      echo "  - No iCloud Knowledge found"
    fi
  fi
else
  echo ""
  echo "  ℹ Options:"
  echo "    --sync   Symlink Memory & Knowledge to iCloud (real-time sync)"
  echo "    --pull   Copy from iCloud to local (one-time, no symlink)"
fi

# ── Done ──
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  ✅ Done! Restart Claude Code to apply."
echo ""
echo "  Installed:"
echo "    ~/.claude/settings.json    (deny rules + hooks + statusline + env)"
echo "    ~/.claude/statusline.sh    (dir + branch / model + context + cost)"
echo "    ~/.claude/CLAUDE.md        (global instructions)"
if [[ "$SYNC" == "true" ]]; then
echo "    Memory    → iCloud Drive/claude-memory (symlinked)"
echo "    Knowledge → iCloud Drive/Knowledge (symlinked)"
elif [[ "$PULL" == "true" ]]; then
echo "    Memory    ← iCloud Drive/claude-memory (copied)"
echo "    Knowledge ← iCloud Drive/Knowledge (copied)"
fi
echo "══════════════════════════════════════════════════════════"
