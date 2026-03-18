#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════
# Claude Code Config Installer
# Installs: settings.json, statusline.sh, CLAUDE.md
# Usage: ./install.sh [--force]
# ══════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
FORCE="${1:-}"

echo "══════════════════════════════════════════════════════════"
echo "  Claude Code Config Installer"
echo "══════════════════════════════════════════════════════════"

mkdir -p "$CLAUDE_DIR"

# ── Helper: safe copy with backup ──
safe_install() {
  local src="$1" dst="$2" name="$3"
  if [[ -f "$dst" && "$FORCE" != "--force" ]]; then
    # Diff check - skip if identical
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

# ── settings.json ──
echo ""
echo "▶ Installing settings..."
safe_install "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"

# ── statusline.sh ──
echo ""
echo "▶ Installing statusline..."
safe_install "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh" "statusline.sh"
chmod +x "$CLAUDE_DIR/statusline.sh"

# ── CLAUDE.md ──
echo ""
echo "▶ Installing CLAUDE.md..."
safe_install "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"

# ── Verify dependencies ──
echo ""
echo "▶ Checking dependencies..."
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

# ── Test statusline ──
echo ""
echo "▶ Testing statusline..."
TEST_OUTPUT=$(echo '{"model":{"display_name":"Test"},"context_window":{"used_percentage":25,"context_window_size":1000000,"current_usage":{"input_tokens":1000,"cache_read_input_tokens":500}},"cost":{"total_cost_usd":0.5,"total_lines_added":10,"total_lines_removed":3,"total_duration_ms":60000},"workspace":{"current_dir":"'"$HOME"'","project_dir":""}}' | "$CLAUDE_DIR/statusline.sh" 2>&1) && echo "  ✓ Statusline works" || echo "  ✗ Statusline failed: $TEST_OUTPUT"

# ── Done ──
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  ✅ Done! Restart Claude Code to apply."
echo ""
echo "  Installed:"
echo "    ~/.claude/settings.json    (settings + deny rules + hooks)"
echo "    ~/.claude/statusline.sh    (2-line status: dir+branch / model+context)"
echo "    ~/.claude/CLAUDE.md        (global instructions)"
echo "══════════════════════════════════════════════════════════"
