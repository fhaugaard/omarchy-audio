# Omarchy Audio (`skye.audio`)

[![Omarchy Plugin](https://img.shields.io/badge/Omarchy-Plugin-4a86e8?style=flat-square)](https://omarchy.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![PipeWire](https://img.shields.io/badge/Audio-PipeWire%20%2F%20WirePlumber-blueviolet?style=flat-square)](https://pipewire.org/)

An enhanced sound control panel and audio mixer for the [Omarchy](https://omarchy.org/) desktop shell. Built on **Quickshell**, **PipeWire**, and **WirePlumber**.

This plugin elevates the stock `omarchy.audio` experience with **instant inline device renaming**, **independent per-device level controls**, **per-application stream mixing**, **MPRIS media correlation**, **bundled CLI utility**, and **full keyboard navigation**.

---

## ✨ Features

### 🏷️ Direct Inline Device Renaming
- **Instant rename**: Click the pencil icon (`󰏫`) or **Right-Click** directly on any output or input device row.
- **Persistent & Seamless**: Custom aliases are saved to `~/.config/omarchy/audio-renames.json` and generated into WirePlumber configuration (`50-device-rename.conf`).
- **No dropouts or restarts**: Renames apply instantly without restarting WirePlumber or interrupting active music, voice calls, or streams.
- **Hardware Reset**: Revert back to the system's default device name at any time with a single click (`󰑐`).
- **Clean Naming**: Automatically filters out noisy hardware/kernel prefixes (such as `sof-soundwire`, `built-in audio`, and long ALSA descriptors).

### 🎚️ Independent Per-Device Level Controls
- **Collapsible view**: Click **"Show levels"** / **"Hide levels"** (`󰝝` / `󰝞`) to toggle discrete per-device sliders.
- **Dedicated Volume & Gain**: Adjust individual hardware outputs (speakers, headphones, DACs) and inputs (microphones, webcams) independently from the default master channel.
- **Live percentage indicators**: Real-time volume and gain percentage readouts for every connected device.

### 🎧 Smart Output & Input Switching
- **One-click switching**: Quickly change your default playback output or recording input.
- **Automatic Jack Availability**: Dynamically detects and filters disconnected or unavailable audio endpoints.
- **Adaptive Device Glyphs**: Contextual icons for headphones (`󰋋`), Bluetooth (`󰂯`), HDMI/DisplayPort (`󰍹`), webcams (`󰄀`), and speakers (`󰓃`).
- **DSP & Tuning Sink Awareness**: Correctly resolves physical devices through virtual speaker tunings, EasyEffects, and DSP sinks.

### 🎛️ Per-Application Stream Mixer
- **Application Level Sliders**: Control volume individually for active apps (browsers, music players, games, Discord).
- **Volume Boost**: Boost audio up to **150%** for quiet applications.
- **MPRIS Integration**: Intelligent player matching correlates generic stream identifiers (e.g., `audio-src`, Chromium streams) to active media players like Spotify and ALSA apps.

### ⚡ Hero Controls & Bar Integration
- **Hero Mute Switch**: Master power switch on the header to instantly mute/unmute all audible channels.
- **Mood Volume Ladder**: Playful, descriptive volume levels from *"Whisper"* to *"Concert hall"*.
- **Scroll Wheel Volume**: Adjust master volume directly by scrolling over the bar icon, complete with On-Screen Display (`omarchy.osd`) popup integration.

---

## ⌨️ Keyboard Shortcuts & Navigation

The audio panel features complete keyboard accessibility with Vim-friendly bindings:

| Key | Action |
|---|---|
| <kbd>j</kbd> / <kbd>↓</kbd> | Move focus downward (header → master → device rows → application streams) |
| <kbd>k</kbd> / <kbd>↑</kbd> | Move focus upward |
| <kbd>h</kbd> / <kbd>←</kbd> | Decrease volume by 5% on the focused item |
| <kbd>l</kbd> / <kbd>→</kbd> | Increase volume by 5% on the focused item |
| <kbd>m</kbd> / <kbd>M</kbd> | Toggle mute on the focused item (master slider, device, or stream) |
| <kbd>Enter</kbd> / <kbd>Space</kbd> | Select active device / toggle master mute |
| <kbd>Tab</kbd> / <kbd>Shift+Tab</kbd> | Switch to next / previous panel |
| <kbd>Esc</kbd> | Cancel inline rename / close panel |

---

## 📦 Installation & Setup

### 🚀 One-Step Install (Recommended)

Install and enable the plugin directly using the Omarchy CLI:

```bash
omarchy plugin add https://github.com/fhaugaard/omarchy-audio.git --enable --yes
```

Everything in the UI and sound mixer works immediately out of the box with zero extra configuration.

*(Optional)* To make the bundled `omarchy-audio-rename` CLI available globally in your terminal `$PATH`:

```bash
~/.config/omarchy/plugins/skye.audio/setup.sh --yes
```

---

### 🛠️ Manual Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/fhaugaard/omarchy-audio.git ~/.config/omarchy/plugins/skye.audio
   ```

2. **Run setup**:
   ```bash
   ~/.config/omarchy/plugins/skye.audio/setup.sh
   ```

3. *(Optional)* If configuring manually without `setup.sh`, add `"skye.audio"` to `~/.config/omarchy/shell.json`:
   ```jsonc
   {
     "bar": {
       "layout": {
         "right": [
           { "id": "omarchy.network" },
           { "id": "skye.audio" },
           { "id": "omarchy.power" }
         ]
       }
     },
     "plugins": [
       { "id": "skye.audio" }
     ]
   }
   ```
   Then reload the shell:
   ```bash
   omarchy restart shell
   ```

---

## 💻 CLI Utility (`omarchy-audio-rename`)

The bundled CLI utility provides terminal management of audio device aliases:

```bash
# List all audio devices and their current aliases
omarchy-audio-rename list --all

# Set a custom alias for an audio device (by ID, node name, or partial search)
omarchy-audio-rename set "Yeti Nano" "Studio Microphone"

# Reset a device back to system default name
omarchy-audio-rename reset "Studio Microphone"

# Reset all custom aliases
omarchy-audio-rename reset-all

# Open the Omarchy audio panel directly
omarchy-audio-rename gui
```

---

## 🗂️ Project Structure

```
omarchy-audio/
├── bin/
│   └── omarchy-audio-rename  # Bundled CLI backend & WirePlumber manager
├── setup.sh                  # Optional automated helper & CLI symlinker
├── manifest.json             # Plugin manifest and bar widget registration
├── Panel.qml                 # Main audio mixer popup, hero header, device list, and streams
├── Model.js                  # Device glyph resolution, label formatting, and audio models
└── README.md                 # Documentation
```

---

## 📄 License

MIT © [Omarchy Contributors](LICENSE)
