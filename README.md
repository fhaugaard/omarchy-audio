# Omarchy Audio (`skye.audio`)

An enhanced audio mixer and sound control panel bar widget for the [Omarchy](https://omarchy.org/) desktop shell (built on Quickshell and PipeWire / WirePlumber).

This plugin extends Omarchy's native `omarchy.audio` bar widget with **direct inline audio device renaming**, **independent per-device volume levels**, **Pro Audio profile management**, **multi-device output routing**, seamless device selection, per-application stream volume management, and keyboard navigation.

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

### 🔀 Multi-Device Output Routing & Multi-Output Playback
- **Per-Application Routing**: Route individual applications (Discord, Spotify, games, web browsers) to any connected output device via the expandable **󰌹 Route** matrix with instantaneous optimistic updates.
- **Custom Multi-Output**: Select any custom subset of connected devices (e.g. Desktop Speakers + Monitor HDMI) or click **"Select all"** to play synchronized audio across chosen outputs simultaneously via PipeWire's native `module-combine-sink` with independent per-device fine-tuning.

> [!NOTE]
> **Known Behavior**: When selecting more than 2 audio devices or deselecting devices in multi-select mode, active playback audio may pause depending on the sound server and application stream state.

### 🎛️ Top-Aligned Playback Sources & Solo Mode
- **Collapsible by Default with Inline Chiron**: Features a sleek, continuous animated marquee ticker directly on the header line displaying active sources (`Spotify, Firefox, Discord, ...`), and expands on click to reveal full cards.
- **Horizontal Card Deck**: Active application streams are elevated to the top of the panel in a horizontal card carousel with dedicated mouse wheel, touchpad, and keyboard horizontal scrolling.
- **Per-Stream Solo Mode**: Isolate any application's audio with the **󰓃 Solo** toggle; all other streams are muted instantly, with previous mute states restored when Solo is released or when the application exits.
- **Dedicated Stream Controls**: Discrete Mute (`󰝟` / `󰕾`), Solo (`󰓃`), Volume Slider with up to **150% Volume Boost**, and expandable **󰌹 Route** output selector on every card.
- **Smart App Glyphs**: Automatically renders recognizable branding glyphs for Spotify (`󰓇`), Discord (`󰙯`), Firefox/Zen (`󰈹`), Chrome (`󰊯`), VLC (`󰕼`), games (`󰊗`), and music players (`󰎆`).

### ⚡ Hero Controls & Bar Integration
- **Hero Mute Switch**: Master power switch on the header to instantly mute/unmute all audible channels.
- **Mood Volume Ladder**: Playful, descriptive volume levels from *"Whisper"* to *"Concert hall"*.
- **Scroll Wheel Volume**: Adjust master volume directly by scrolling over the bar icon, complete with On-Screen Display (`omarchy.osd`) popup integration.

---

## ⌨️ Keyboard Shortcuts & Navigation

The audio panel features complete keyboard accessibility with Vim-friendly bindings:

| Key | Action |
|---|---|
| <kbd>j</kbd> / <kbd>↓</kbd> | Move focus downward (header → playback stream cards → master → device rows) |
| <kbd>k</kbd> / <kbd>↑</kbd> | Move focus upward |
| <kbd>h</kbd> / <kbd>←</kbd> | Decrease volume by 5% on the focused item |
| <kbd>l</kbd> / <kbd>→</kbd> | Increase volume by 5% on the focused item |
| <kbd>m</kbd> / <kbd>M</kbd> | Toggle mute on the focused item (master slider, device, or stream) |
| <kbd>s</kbd> / <kbd>S</kbd> | Toggle Solo mode on the focused stream card |
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

*(Optional)* To make the bundled CLI utilities available globally in your terminal `$PATH`:

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

## 💻 CLI Utilities

### `omarchy-audio-rename`
Terminal management of audio device aliases:

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

### `omarchy-audio-routing`
Pro Audio, simultaneous playback, and stream routing control:

```bash
# List sound cards and profile states as JSON
omarchy-audio-routing list-cards

# Toggle simultaneous playback on all outputs
omarchy-audio-routing toggle-simultaneous

# Move an application stream to a specific sink
omarchy-audio-routing route-stream-to-sink Spotify alsa_output.pci-0000_2f_00.4.analog-stereo
```

---

## 🗂️ Project Structure

```
omarchy-audio/
├── bin/
│   ├── omarchy-audio-rename   # Bundled CLI backend & WirePlumber manager
│   └── omarchy-audio-routing  # Simultaneous routing & stream movement engine
├── setup.sh                   # Automated helper & CLI symlinker
├── manifest.json              # Plugin manifest and bar widget registration
├── Panel.qml                  # Main audio mixer popup, hero header, device list, and streams
├── Model.js                   # Device glyph resolution, label formatting, and audio models
└── README.md                  # Documentation
```

---

## 📄 License

MIT © [Omarchy Contributors](LICENSE)
