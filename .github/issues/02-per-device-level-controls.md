### Problem Description
Currently, volume adjustments primarily affect the system default sink or active streams. When multiple audio devices are connected, adjusting non-default device volumes requires switching defaults or using third-party tools (`wpctl`, `pavucontrol`).

### User Story
As a user, I want individual volume and gain sliders directly on each device row/card so I can calibrate individual hardware levels before or during output switching.

---

### Key Requirements
- [ ] **Per-Sink Level Sliders**:
  - Add volume level slider and percentage indicator to all available output devices in the Sinks list.
  - Include individual hardware mute toggles per device.
- [ ] **Per-Source Input Gain Sliders**:
  - Add input gain sliders and peak level meters for every microphone / audio source.
- [ ] **WirePlumber Persistence**:
  - Ensure volume adjustments use WirePlumber node volume properties (`node.volume` / `wpctl set-volume <node-id> <val>`) to persist across sessions and device re-connections.
- [ ] **Over-Amplification Toggle / Indicator**:
  - Indicate when a device volume is pushed past 100% (if allowed in shell config).

---

### Acceptance Criteria
1. Changing the slider for device B adjusts B's hardware/node volume without changing default device A's volume.
2. Volume levels update reactively if changed externally (e.g., via hardware volume wheels or `wpctl`).
3. Individual device mute states reflect accurately without affecting the global master mute status.
