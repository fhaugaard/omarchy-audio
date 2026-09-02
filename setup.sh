#!/usr/bin/env bash
# omarchy-audio setup script
# Configures the skye.audio plugin, symlinks the CLI renamer, and reloads the shell.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ASSUME_YES=0

while (( $# > 0 )); do
  case "$1" in
    -y|--yes)
      ASSUME_YES=1
      shift
      ;;
    -h|--help)
      echo "Usage: ./setup.sh [--yes]"
      echo "Set up Omarchy Audio plugin and CLI renamer utility."
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

echo "========================================================"
echo "  Omarchy Audio (skye.audio) Setup"
echo "========================================================"

# 1. Ensure directories exist
mkdir -p "$HOME/.local/bin" "$HOME/.config/omarchy" "$HOME/.config/wireplumber/wireplumber.conf.d"

# 2. Make bin/omarchy-audio-rename executable and link to ~/.local/bin
RENAME_SRC="$SCRIPT_DIR/bin/omarchy-audio-rename"
if [[ -f "$RENAME_SRC" ]]; then
  chmod +x "$RENAME_SRC"
  ln -sfn "$RENAME_SRC" "$HOME/.local/bin/omarchy-audio-rename"
  echo "✓ Linked omarchy-audio-rename CLI into $HOME/.local/bin/"
else
  echo "⚠️  $RENAME_SRC not found, skipping CLI symlink."
fi

# 3. Initialize audio-renames.json if missing
RENAMES_JSON="$HOME/.config/omarchy/audio-renames.json"
if [[ ! -f "$RENAMES_JSON" ]]; then
  echo "{}" > "$RENAMES_JSON"
  echo "✓ Initialized $RENAMES_JSON"
fi

# 4. Configure shell.json to include skye.audio if needed
SHELL_CONFIG="$HOME/.config/omarchy/shell.json"
if [[ -f "$SHELL_CONFIG" ]] && command -v jq &>/dev/null; then
  # Check if skye.audio is already configured in the layout
  has_widget=$(jq '.bar.layout.right // [] | any(.[]; .id == "skye.audio") or (.bar.layout.left // [] | any(.[]; .id == "skye.audio")) or (.bar.layout.center // [] | any(.[]; .id == "skye.audio"))' "$SHELL_CONFIG" 2>/dev/null || echo "false")
  
  if [[ "$has_widget" != "true" ]]; then
    # Replace omarchy.audio with skye.audio in bar layout if present, otherwise add to right section
    has_omarchy_audio=$(jq '.bar.layout.right // [] | any(.[]; .id == "omarchy.audio")' "$SHELL_CONFIG" 2>/dev/null || echo "false")
    
    if [[ "$has_omarchy_audio" == "true" ]]; then
      jq '(.bar.layout.right[] | select(.id == "omarchy.audio")).id = "skye.audio"' "$SHELL_CONFIG" > "${SHELL_CONFIG}.tmp" && mv "${SHELL_CONFIG}.tmp" "$SHELL_CONFIG"
      echo "✓ Replaced omarchy.audio with skye.audio in bar layout"
    fi
  fi

  # Ensure skye.audio is listed in plugins array if present
  has_plugin=$(jq '.plugins // [] | any(.[]; .id == "skye.audio")' "$SHELL_CONFIG" 2>/dev/null || echo "false")
  if [[ "$has_plugin" != "true" ]]; then
    jq '.plugins += [{"id": "skye.audio"}]' "$SHELL_CONFIG" > "${SHELL_CONFIG}.tmp" && mv "${SHELL_CONFIG}.tmp" "$SHELL_CONFIG"
    echo "✓ Added skye.audio to plugins list in $SHELL_CONFIG"
  fi
fi

# 5. Reload shell if running
if command -v omarchy-shell &>/dev/null && omarchy-shell shell ping &>/dev/null; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  echo "✓ Reloaded plugins in running Omarchy shell"
fi

echo ""
echo "🎉 Setup complete! Omarchy Audio is ready to use."
