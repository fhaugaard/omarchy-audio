### Problem Description
Users lack visual feedback to immediately verify whether sound is actively playing, clipping, or quiet without checking external audio utilities.

### User Story
As a user, I want a toggleable real-time waveform or spectrum viewer inside the audio panel so I can visually inspect live audio activity and levels on demand.

---

### Key Requirements
- [ ] **Visualizer Toggle Control**:
  - Add a header/toolbar toggle button (`󰕓` / `󰐍`) to show/hide the waveform drawer.
  - Smooth expand/collapse animation without layout stutter.
- [ ] **Real-Time Audio Tap / Monitor**:
  - Tap into PipeWire peak monitoring, PCM stream data, or Canvas/QML shader for live waveform rendering.
  - Configurable target (visualize Master Output, Selected Input Source, or Active App Stream).
- [ ] **Performance & Resource Optimization**:
  - Render at smooth 60 FPS when the panel is open and visualizer is toggled on.
  - Completely suspend audio tapping and rendering timers when the visualizer is toggled off or the panel popup is closed to avoid idle CPU overhead.
- [ ] **Visual Styling**:
  - Clean waveform / oscilloscope or multi-band bar visualizer adhering to Omarchy theme colors.

---

### Acceptance Criteria
1. Toggling the waveform button smoothly reveals the visualizer canvas.
2. Waveform animates in real-time matching active playback or input sound.
3. CPU usage drops to 0% for the visualizer when the widget is hidden or visualizer is toggled off.
4. Visualizer accurately reflects volume changes and silence/mute states.
