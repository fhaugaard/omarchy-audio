#!/usr/bin/env bash
set -euo pipefail

REPO="fhaugaard/omarchy-audio"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Publishing issues to $REPO..."

echo "Creating Issue 1: Pro Audio, Multichannel & Multi-Device Output Routing..."
gh issue create \
  --repo "$REPO" \
  --title "feat(routing): Support Pro Audio profile switching, multichannel splitting, and multi-device output routing" \
  --body-file "$SCRIPT_DIR/issues/01-multi-device-routing-pro-audio.md" \
  --label "enhancement"

echo "Creating Issue 2: Per-Device Volume & Level Settings..."
gh issue create \
  --repo "$REPO" \
  --title "feat(levels): Independent volume and level controls per device (sinks and sources)" \
  --body-file "$SCRIPT_DIR/issues/02-per-device-level-controls.md" \
  --label "enhancement"

echo "Creating Issue 3: Playback Sources Section Redesign..."
gh issue create \
  --repo "$REPO" \
  --title "feat(ui): Redesign Playback Sources section as top-aligned scrollable cards with Mute and Solo" \
  --body-file "$SCRIPT_DIR/issues/03-playback-sources-cards-mute-solo.md" \
  --label "enhancement"

echo "Creating Issue 4: Toggleable Waveform Visualizer..."
gh issue create \
  --repo "$REPO" \
  --title "feat(visualizer): Add toggleable real-time audio waveform / spectrum visualizer" \
  --body-file "$SCRIPT_DIR/issues/04-toggleable-waveform-visualizer.md" \
  --label "enhancement"

echo "All 4 issues successfully published!"
