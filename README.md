# Omarchy Sound Control Panel (`skye.audio`)

An enhanced audio mixer and sound control panel bar widget for the [Omarchy](https://omarchy.org/) desktop shell (built on Quickshell and PipeWire / WirePlumber).

This plugin extends Omarchy's native `omarchy.audio` bar widget with **direct inline audio device renaming**, seamless device selection, per-application stream volume management, and keyboard navigation.

---

## Features

- **Inline Device Renaming**:
  - Click the **pencil icon (`󰏫`)** next to any input/output device.
  - Or **Right-click** directly on any device row to enter inline edit mode.
  - Custom names are saved directly through `omarchy-audio-rename` and WirePlumber for persistent system-wide renaming.
- **Output & Input Management**: Fast switching of default sink (speakers, headphones) and source (microphones).
- **Per-Application Audio Mixer**: Individual volume controls for active audio streams (browsers, music players, games, Discord).
- **Volume & Mute Controls**: Volume sliders, peak level indicators, and quick-mute toggles.
- **Full Keyboard Navigation**: Arrow key focus and navigation support.

---

## Installation

### 1. Requirements
- [Omarchy](https://omarchy.org/) desktop shell
- [`omarchy-audio-rename`](https://github.com/fhaugaard/omarchy-audio-renamer) CLI utility

### 2. Install as a Shell Plugin
Clone this repository into your Omarchy user plugins directory:

```bash
git clone https://github.com/fhaugaard/omarchy-audio.git ~/.config/omarchy/plugins/skye.audio
```

Enable the plugin in your `~/.config/omarchy/shell.json` (or via `omarchy plugin clone omarchy.audio`).

### 3. Reload Shell
```bash
omarchy restart shell
```

---

## Files

- `manifest.json`: Shell plugin declaration and kind definition.
- `Panel.qml`: Main sound control popup interface and mixer layout.
- `Model.js`: Icon glyph resolution, category mapping, and volume utilities.

---

## License
MIT
