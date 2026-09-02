### Problem Description
Currently, active playback sources (per-application audio streams such as Chromium, Discord, Spotify, CLIamp, games) are positioned at the bottom of the mixer in a vertical list. For users actively managing audio playback, elevating playback sources to the top of the panel and providing per-app **Mute** and **Solo** controls provides a much faster and more intuitive mixing workflow.

### User Story
As a user running multiple audio applications, I want active playback sources prominently positioned at the top of the panel as scrollable cards so I can quickly monitor, adjust volume, mute, or isolate (solo) specific app streams (e.g., isolating a voice call or music player while muting browser tabs).

---

### Proposed UI / Layout
- **Top Alignment**: Move the Playback Sources / Application Streams section to the very top of `Panel.qml` (above master controls and physical output device selectors).
- **Horizontal Scrollable Card Carousel**:
  - Render active playback streams as compact, visually distinct cards.
  - Card elements:
    - Application icon / MPRIS artwork / stream glyph.
    - Application display name (with resolved friendly stream label).
    - Compact volume slider / level indicator.
    - Output routing badge.
  - Smooth horizontal scrolling / swipe navigation with keyboard navigation support (Left/Right arrow keys).
- **Stream Controls**:
  - **Mute Toggle (`󰝟` / `󰕾`)**: Mutes/unmutes the specific application stream.
  - **Solo Toggle (`󰓃` / `S`)**: 
    - Isolates the chosen playback source by muting all other active application playback streams.
    - Toggling Solo off restores the prior mute states of all other streams.
    - Clear visual badge/border indicating when a stream is in "Solo" mode.

---

### Technical & PipeWire Considerations
- Track and snapshot previous mute states of all `audioStreams` nodes when a source enters Solo mode.
- React to newly launched playback streams while Solo mode is active (auto-mute new incoming streams or leave them muted until Solo is deactivated).
- Clean up Solo state gracefully if the soloed application stream terminates/closes.

---

### Acceptance Criteria
1. Playback sources (application audio streams) appear at the top of the panel in a horizontal scrollable card deck.
2. Tapping **Mute** on a card toggles the stream's mute state directly on its PipeWire stream node.
3. Tapping **Solo** on an app card mutes all other active playback streams; turning Solo off restores their previous mute states.
4. Closing a soloed app automatically clears the Solo lock without leaving remaining streams stuck muted.
5. Empty state: Gracefully collapses or shows an unobtrusive placeholder when no playback streams are active.
