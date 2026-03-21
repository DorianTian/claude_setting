#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════
# claude-config — Claude Code Config Installer
# Usage:
#   claude-config                    Interactive mode
#   claude-config --all              Install all config files
#   claude-config --statusline       Install statusline only
#   claude-config --knowledge        Symlink Knowledge to iCloud
#   claude-config --ai-daily         Symlink AI-Daily to iCloud
#   claude-config --link             Register CLI command (~/.local/bin/claude-config)
#   Flags can be combined: claude-config --all --knowledge --ai-daily
# ══════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# ── Parse flags ──
INSTALL_SETTINGS=false
INSTALL_STATUSLINE=false
INSTALL_CLAUDE_MD=false
KNOWLEDGE=false
AI_DAILY=false
LINK=false
INTERACTIVE=false

if [[ $# -eq 0 ]]; then
  INTERACTIVE=true
else
  for arg in "$@"; do
    case "$arg" in
      --all) INSTALL_SETTINGS=true; INSTALL_STATUSLINE=true; INSTALL_CLAUDE_MD=true ;;
      --statusline) INSTALL_STATUSLINE=true ;;
      --knowledge) KNOWLEDGE=true ;;
      --ai-daily) AI_DAILY=true ;;
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
        echo "    --knowledge       Symlink Knowledge to iCloud"
        echo "    --ai-daily        Symlink AI-Daily to iCloud"
        echo ""
        echo "  Other:"
        echo "    --link            Register 'claude-config' CLI command"
        echo "    --help            Show this help"
        echo ""
        echo "  Flags can be combined: claude-config --all --knowledge --ai-daily"
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
  echo "    5) Sync Knowledge      → iCloud"
  echo "    6) Sync AI-Daily       → iCloud"
  echo ""
  echo "  Other:"
  echo "    7) Register CLI        (claude-config command)"
  echo "    0) Full setup          (all configs + sync Knowledge & AI-Daily + CLI)"
  echo ""
  printf "  Enter choices (e.g. 1 2 5, or 0 for full): "
  read -r choices

  for choice in $choices; do
    case "$choice" in
      1) INSTALL_SETTINGS=true ;;
      2) INSTALL_STATUSLINE=true ;;
      3) INSTALL_CLAUDE_MD=true ;;
      4) INSTALL_SETTINGS=true; INSTALL_STATUSLINE=true; INSTALL_CLAUDE_MD=true ;;
      5) KNOWLEDGE=true ;;
      6) AI_DAILY=true ;;
      7) LINK=true ;;
      0) INSTALL_SETTINGS=true; INSTALL_STATUSLINE=true; INSTALL_CLAUDE_MD=true
         KNOWLEDGE=true; AI_DAILY=true; LINK=true ;;
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
ICLOUD_KNOWLEDGE="$ICLOUD_DIR/Knowledge"
ICLOUD_AI_DAILY="$ICLOUD_DIR/AI-Daily"

# ── Helper: safe copy with backup ──
safe_install() {
  local src="$1" dst="$2" name="$3"
  if [[ -f "$dst" ]]; then
    if diff -q "$src" "$dst" &>/dev/null; then
      echo "  = $name (unchanged)"
      return
    fi
    echo "  ↻ $name (overwritten)"
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
  if [[ "$INSTALL_SETTINGS" == "true" && -f "$SCRIPT_DIR/settings.local.json" ]]; then
    if [[ -f "$CLAUDE_DIR/settings.local.json" ]]; then
      echo "  ⊕ settings.local.json (merging permissions)"
      jq -s '
        .[0] as $src | .[1] as $dst |
        ($src.permissions.allow // []) + ($dst.permissions.allow // []) | unique |
        $src * $dst * { permissions: { allow: . } }
      ' "$SCRIPT_DIR/settings.local.json" "$CLAUDE_DIR/settings.local.json" > "$CLAUDE_DIR/settings.local.json.tmp" \
        && mv "$CLAUDE_DIR/settings.local.json.tmp" "$CLAUDE_DIR/settings.local.json"
    else
      safe_install "$SCRIPT_DIR/settings.local.json" "$CLAUDE_DIR/settings.local.json" "settings.local.json"
    fi
  fi
  if [[ "$INSTALL_STATUSLINE" == "true" ]]; then
    # CCometixLine (Rust) — requires cargo
    if command -v ccometixline &>/dev/null; then
      echo "  ✓ ccometixline already installed"
    else
      echo "  ▶ Installing CCometixLine..."
      if ! command -v cargo &>/dev/null; then
        echo "    Installing Rust..."
        if command -v brew &>/dev/null; then
          brew install rust
        else
          curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
          source "$HOME/.cargo/env"
        fi
      fi
      if command -v cargo &>/dev/null; then
        cargo install --git https://github.com/Haleclipse/CCometixLine.git 2>/dev/null && echo "  ✓ ccometixline installed" || echo "  ✗ ccometixline install failed"
      else
        echo "  ✗ cargo not found, cannot install ccometixline"
      fi
    fi
  fi
  if [[ "$INSTALL_CLAUDE_MD" == "true" ]]; then
    ICLOUD_CLAUDE_MD="$ICLOUD_DIR/claude-memory/CLAUDE.md"
    if [[ -L "$CLAUDE_DIR/CLAUDE.md" ]]; then
      echo "  = CLAUDE.md (already symlinked)"
    elif [[ -f "$ICLOUD_CLAUDE_MD" ]]; then
      if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
        rm -f "$CLAUDE_DIR/CLAUDE.md"
        echo "  ↻ Local CLAUDE.md removed (iCloud is source of truth)"
      fi
      ln -s "$ICLOUD_CLAUDE_MD" "$CLAUDE_DIR/CLAUDE.md"
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
  command -v ccometixline &>/dev/null && echo "  ✓ ccometixline $(ccometixline --version 2>&1)" || echo "  ✗ ccometixline not found"
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

# ── Sync Knowledge (symlink) ──
if [[ "$KNOWLEDGE" == "true" ]]; then
  echo ""
  echo "▶ Sync Knowledge → iCloud..."
  if check_icloud; then
    if [[ -L "$HOME/Knowledge" ]]; then
      echo "  = Knowledge (already symlinked)"
    else
      mkdir -p "$ICLOUD_KNOWLEDGE"
      if [[ -d "$HOME/Knowledge" ]]; then
        rm -rf "$HOME/Knowledge"
        echo "  ↻ Local Knowledge removed (iCloud is source of truth)"
      fi
      ln -s "$ICLOUD_KNOWLEDGE" "$HOME/Knowledge"
      echo "  ✓ Knowledge → iCloud Drive/Knowledge"
    fi
  fi
fi

# ── Sync AI-Daily (symlink) ──
if [[ "$AI_DAILY" == "true" ]]; then
  echo ""
  echo "▶ Sync AI-Daily → iCloud..."
  if check_icloud; then
    if [[ -L "$HOME/AI-Daily" ]]; then
      echo "  = AI-Daily (already symlinked)"
    else
      mkdir -p "$ICLOUD_AI_DAILY"
      if [[ -d "$HOME/AI-Daily" ]]; then
        rm -rf "$HOME/AI-Daily"
        echo "  ↻ Local AI-Daily removed (iCloud is source of truth)"
      fi
      ln -s "$ICLOUD_AI_DAILY" "$HOME/AI-Daily"
      echo "  ✓ AI-Daily → iCloud Drive/AI-Daily"
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
[[ "$KNOWLEDGE" == "true" ]] && ITEMS+=("Knowledge→iCloud")
[[ "$AI_DAILY" == "true" ]] && ITEMS+=("AI-Daily→iCloud")
[[ "$LINK" == "true" ]] && ITEMS+=("CLI:claude-config")

if [[ ${#ITEMS[@]} -eq 0 ]]; then
  echo "  Nothing selected. Run 'claude-config' for interactive mode."
else
  echo "  ✅ Done! $(IFS=', '; echo "${ITEMS[*]}")"
  echo "  Restart Claude Code to apply."
fi
echo "══════════════════════════════════════════════════════════"
