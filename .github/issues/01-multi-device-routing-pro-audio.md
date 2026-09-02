### Problem Description
1. Audio playback streams are currently bound to a single active sink (output device), preventing users from simultaneously streaming audio to multiple destinations (e.g., desktop speakers + wireless headphones).
2. Advanced audio interfaces (e.g., Focusrite Scarlett, MOTU, Behringer, USB multichannel DACs) are often locked into standard stereo profiles. Without access to the PipeWire **Pro Audio** profile, users cannot independently address individual hardware channels (e.g., separating Headphone Out 3/4 from Main Out 1/2, or routing mono audio to subwoofers/cue sends).

### User Story
As an audio power user or producer, I want to:
- Switch audio interfaces to their **Pro Audio profile** directly from the UI.
- Break multichannel audio devices into independent mono channels or stereo-linked pairs (e.g., Channels 1–2, Channels 3–4, Channel 5).
- Route and split individual application playback streams across multiple devices or sub-channel outputs simultaneously.

---

### Key Requirements

#### 1. Pro Audio Profile Management
- [ ] **Profile Switcher**:
  - Add a profile selection menu or toggle for audio cards (e.g., switching between standard stereo/surround and `pro-audio` via WirePlumber / `wpctl set-profile`).
  - Gracefully handle dynamic port creation when entering `pro-audio` mode.

#### 2. Multichannel Output Grouping & Stereo Linking
- [ ] **Channel Splitting & Pairing Matrix**:
  - Detect raw physical playback channels exposed in Pro Audio mode (e.g., `playback_AUX0` ... `playback_AUXn` / `playback_FL`, `playback_FR`).
  - Provide controls to configure channels as **Stereo-Linked Pairs** (e.g., `Out 1+2`, `Out 3+4`) or **Independent Mono Outputs** (e.g., `Out 1`, `Out 2`).
  - Create and manage virtual sub-sinks or PipeWire loopback nodes (`pw-loopback` / `module-loopback`) for configured channel groups so they appear cleanly in the mixer.

#### 3. Multi-Device & Multi-Channel Stream Splitting
- [ ] **Output Destination Matrix**:
  - Allow per-application streams (and/or master output) to route to multiple physical sinks or sub-channel pairs simultaneously.
  - Dynamically establish PipeWire links without tearing down existing active streams.
- [ ] **Latency & Sync Management**:
  - Ensure sample clock sync and buffer alignment when splitting streams across devices with differing latencies.

---

### Acceptance Criteria
1. Changing an interface's profile to **Pro Audio** exposes all discrete physical output ports in the widget without needing to restart PipeWire.
2. Users can create a stereo-linked output pair (e.g., Channels 3 & 4) or mono outputs that display as assignable targets in the output picker.
3. An application playback stream can be routed to multiple targets simultaneously (e.g., Out 1–2 on Interface A + Bluetooth Headset B).
4. Unchecking or disabling a target immediately unlinks the stream without causing audio pops, glitches, or crashes in remaining outputs.
5. All custom channel groupings and profile selections persist across device re-plugs and reboots.
