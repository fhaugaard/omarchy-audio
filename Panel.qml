import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.Ui
import qs.Commons
import "Model.js" as Model

Panel {
  id: root
  moduleName: "omarchy.audio"
  ipcTarget: "omarchy.audio"

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property var mprisPlayers: Mpris.players ? Mpris.players.values : []
  readonly property var mediaService: bar?.shell?.firstPartyServiceFor("omarchy.media")
  readonly property var activeMediaPlayer: mediaService ? mediaService.activePlayer : null

  readonly property var candidateSinks: {
    var list = []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && n.isSink && !n.isStream) {
        var name = String(n.name || "")
        if (name.indexOf("output.omarchy_combined") === 0) continue
        list.push(n)
      }
    }
    return list
  }

  readonly property var candidateSources: {
    var list = []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && !n.isSink && !n.isStream && isAudioSource(n)) {
        var name = n.name || ""
        if (name === "quickshell") continue
        list.push(n)
      }
    }
    return list
  }

  readonly property var candidateStreams: {
    var list = []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (!n || !n.isStream || !isPlaybackStream(n)) continue
      if (String(n.name || "").indexOf("omarchy_speaker_tuning") === 0) continue
      if (String(n.name || "").indexOf("output.omarchy_combined") === 0) continue
      list.push(n)
    }
    return list
  }

  property var sinkAvailability: ({})
  property bool sinkAvailabilityLoaded: false
  property bool expandOutputLevels: false
  property bool expandInputLevels: false
  property var soundCards: []
  property var streamLinks: ({})
  property var customRenames: ({})

  function isPlaybackStream(node) {
    return Model.isPlaybackStream(node)
  }

  function isAudioSource(node) {
    return Model.isAudioSource(node)
  }

  property var cachedAudioSinks: []
  property var cachedAudioSources: []

  readonly property var rawAudioSinks: {
    var list = []
    for (var i = 0; i < candidateSinks.length; i++)
      if (sinkAvailable(candidateSinks[i])) list.push(candidateSinks[i])
    if (sink && list.indexOf(sink) < 0) list.unshift(sink)
    return list
  }

  readonly property var rawAudioSources: {
    var list = candidateSources.slice()
    if (source && list.indexOf(source) < 0) list.unshift(source)
    return list
  }

  readonly property var audioSinks: rawAudioSinks.length > 0 ? rawAudioSinks : cachedAudioSinks
  readonly property var audioSources: rawAudioSources.length > 0 ? rawAudioSources : cachedAudioSources

  readonly property var audioStreams: {
    var list = []
    for (var i = 0; i < candidateStreams.length; i++)
      if (candidateStreams[i].audio) list.push(candidateStreams[i])
    return list
  }

  property var displayAudioSinks: []
  property var displayAudioSources: []
  property var displayAudioStreams: []

  property string volumeSinkName: ""
  property real wheelAccumulator: 0

  readonly property var volumeSink: {
    if (volumeSinkName === "" || !sink) return sink
    if (volumeSinkName === String(sink.name)) return sink
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && n.isSink && !n.isStream && String(n.name) === volumeSinkName && n.audio)
        return n
    }
    return sink
  }

  onSinkChanged: resolveVolumeSink()

  function resolveVolumeSink() {
    if (!volumeSinkProc.running) volumeSinkProc.running = true
  }

  readonly property real outputVolume: volumeSink && volumeSink.audio ? volumeSink.audio.volume : 0
  readonly property bool outputMuted: volumeSink && volumeSink.audio ? volumeSink.audio.muted : false
  readonly property real inputVolume: source && source.audio ? source.audio.volume : 0
  readonly property bool inputMuted: source && source.audio ? source.audio.muted : false

  onRawAudioSinksChanged: if (rawAudioSinks.length > 0) cachedAudioSinks = rawAudioSinks
  onRawAudioSourcesChanged: if (rawAudioSources.length > 0) cachedAudioSources = rawAudioSources

  property string focusSection: "output"
  property int selectedIndex: -1
  property bool cursorActive: false

  readonly property bool headerHasCursor: cursorActive && focusSection === "header"
  readonly property bool hasOutput: !!(volumeSink && volumeSink.audio)
  readonly property bool hasInput: !!(source && source.audio)
  readonly property bool anyAudible: (hasOutput && !outputMuted) || (hasInput && !inputMuted)
  readonly property string toggleHint: anyAudible ? "Mute" : "Unmute"

  readonly property color hoverFill: bar
    ? Style.hoverFillFor(bar.foreground, Color.accent)
    : "transparent"
  readonly property color selectedFill: bar
    ? Style.selectedFillFor(bar.foreground, Color.accent)
    : "transparent"

  function sectionCount(section) {
    if (section === "output") return displayAudioSinks.length
    if (section === "input") return displayAudioSources.length
    if (section === "streams") return displayAudioStreams.length
    return 0
  }

  function sectionVisible(section) {
    if (section === "output") return true
    if (section === "input") return displayAudioSources.length > 0 || !!source
    if (section === "streams") return displayAudioStreams.length > 0
    return false
  }

  function sectionHasSlider(section) {
    if (section === "output") return true
    if (section === "input") return !!source
    return false
  }

  readonly property var visibleSections: {
    var list = []
    if (sectionVisible("output")) list.push("output")
    if (sectionVisible("input")) list.push("input")
    if (sectionVisible("streams")) list.push("streams")
    return list
  }

  function moveCursor(delta) {
    var sections = visibleSections
    if (sections.length === 0) return
    if (focusSection === "header") {
      if (delta > 0) { focusSection = sections[0]; selectedIndex = sectionHasSlider(sections[0]) ? -1 : 0 }
      return
    }
    var sIdx = sections.indexOf(focusSection)
    if (sIdx < 0) { focusSection = sections[0]; selectedIndex = sectionHasSlider(focusSection) ? -1 : 0; return }

    var idx = selectedIndex
    var max = sectionCount(focusSection) - 1
    var hasSlider = sectionHasSlider(focusSection)
    var floor = hasSlider ? -1 : 0

    if (delta > 0) {
      if (idx < max) { selectedIndex = idx + 1; return }
      if (sIdx < sections.length - 1) {
        focusSection = sections[sIdx + 1]
        selectedIndex = sectionHasSlider(focusSection) ? -1 : 0
      }
    } else {
      if (idx > floor) { selectedIndex = idx - 1; return }
      if (sIdx > 0) {
        focusSection = sections[sIdx - 1]
        var prevMax = sectionCount(focusSection) - 1
        selectedIndex = prevMax >= 0 ? prevMax : (sectionHasSlider(focusSection) ? -1 : 0)
      } else {
        focusSection = "header"
      }
    }
  }

  function setHeaderCursor() {
    cursorActive = true
    focusSection = "header"
    selectedIndex = -1
  }

  function moveSection(delta) {
    var sections = visibleSections
    if (sections.length === 0) return
    var current = sections.indexOf(focusSection)
    if (current < 0) current = delta > 0 ? -1 : 0
    var next = (current + delta + sections.length) % sections.length
    focusSection = sections[next]
    selectedIndex = sectionHasSlider(focusSection) ? -1 : 0
    cursorActive = true
  }

  function adjustVolume(delta) {
    if (focusSection === "output" && selectedIndex === -1) {
      setOutputVolume(outputVolume + delta)
      return
    }
    if (focusSection === "input" && selectedIndex === -1) {
      setInputVolume(inputVolume + delta)
      return
    }
    if (focusSection === "streams" && selectedIndex >= 0 && selectedIndex < displayAudioStreams.length) {
      var s = displayAudioStreams[selectedIndex]
      if (s && s.audio) s.audio.volume = Math.max(0, Math.min(1.5, s.audio.volume + delta))
    }
  }

  function activateCursor() {
    if (focusSection === "header") { toggleAllMuted(); return }
    if (focusSection === "output") {
      if (selectedIndex === -1) { toggleOutputMute(); return }
      var sink = displayAudioSinks[selectedIndex]
      if (sink) setDefaultSink(sink)
      return
    }
    if (focusSection === "input") {
      if (selectedIndex === -1) { toggleInputMute(); return }
      var src = displayAudioSources[selectedIndex]
      if (src) setDefaultSource(src)
      return
    }
    if (focusSection === "streams" && selectedIndex >= 0) {
      var st = displayAudioStreams[selectedIndex]
      if (st && st.audio) st.audio.muted = !st.audio.muted
    }
  }

  onOpenedChanged: {
    if (opened) {
      refreshRoutingState()
      refreshDisplayAudioModels()
      focusSection = "output"
      selectedIndex = -1
      cursorActive = false
      Qt.callLater(resetScroll)
    } else {
      clearDisplayAudioModels()
    }
  }

  onAudioSinksChanged: scheduleDisplayAudioModelRefresh()
  onAudioSourcesChanged: scheduleDisplayAudioModelRefresh()
  onAudioStreamsChanged: {
    scheduleDisplayAudioModelRefresh()
    if (opened && !streamLinksProc.running) streamLinksProc.running = true
  }

  function listSnapshot(list) {
    return Model.listSnapshot(list)
  }

  function refreshDisplayAudioModels() {
    if (!opened) return
    displayAudioSinks = listSnapshot(audioSinks)
    displayAudioSources = listSnapshot(audioSources)
    displayAudioStreams = listSnapshot(audioStreams)
    clampCursor()
  }

  function scheduleDisplayAudioModelRefresh() {
    if (!opened) return
    audioModelRefreshTimer.restart()
  }

  function clearDisplayAudioModels() {
    audioModelRefreshTimer.stop()
    displayAudioSinks = []
    displayAudioSources = []
    displayAudioStreams = []
  }

  function resetScroll() {
    if (!scrollArea) return
    var flick = scrollArea.contentItem
    if (flick && flick.contentY !== undefined) flick.contentY = 0
  }

  function ensureCursorVisible(item) {
    if (!item || !scrollArea) return
    var flick = scrollArea.contentItem
    if (!flick || flick.contentY === undefined) return
    var margin = 6
    var maxY = Math.max(0, (flick.contentHeight || 0) - flick.height)
    if (maxY <= Style.space(24) || (root.focusSection === "output" && root.selectedIndex === -1)) {
      flick.contentY = 0
      return
    }
    var pt = item.mapToItem(flick.contentItem || flick, 0, 0)
    var top = pt.y
    var bottom = top + (item.height || 0)
    var viewTop = flick.contentY
    var viewBottom = viewTop + flick.height
    if (top < viewTop + margin) flick.contentY = Math.max(0, Math.min(maxY, top - margin))
    else if (bottom > viewBottom - margin)
      flick.contentY = Math.max(0, Math.min(maxY, bottom + margin - flick.height))
  }

  function clampCursor() {
    var sections = visibleSections
    if (!sections || !sections.length) return
    if (focusSection === "header") return
    if (sections.indexOf(focusSection) < 0) {
      focusSection = visibleSections[0]
      selectedIndex = sectionHasSlider(focusSection) ? -1 : 0
      return
    }
    var count = sectionCount(focusSection)
    var hasSlider = sectionHasSlider(focusSection)
    var floor = hasSlider ? -1 : 0
    if (selectedIndex > count - 1) selectedIndex = Math.max(floor, count - 1)
    if (selectedIndex < floor) selectedIndex = floor
  }

  function outputIcon(volume) {
    if (!sink || !sink.audio) return ""
    if (isHeadphones(sink)) return "󰋋"
    if (outputMuted) return ""
    var v = volume === undefined ? outputVolume : volume
    if (v >= 0.67) return ""
    if (v >= 0.34) return ""
    if (v > 0) return ""
    return ""
  }

  function inputIcon() {
    if (!source || !source.audio) return "󰍭"
    return inputMuted ? "󰍭" : "󰍬"
  }

  function outputVolumeName(volume, muted) {
    return Model.outputVolumeName(volume, muted)
  }

  function setOutputVolume(v) {
    if (!volumeSink || !volumeSink.audio) return outputVolume
    var volume = Math.max(0, Math.min(1, v))
    volumeSink.audio.volume = volume
    return volume
  }

  function showVolumeOsd(volume) {
    if (!bar || !bar.shell) return
    bar.shell.summon("omarchy.osd", JSON.stringify({
      icon: outputIcon(volume),
      value: Math.round(volume * 100)
    }))
  }

  function setInputVolume(v) {
    if (!source || !source.audio) return
    source.audio.volume = Math.max(0, Math.min(1, v))
  }

  function toggleOutputMute() {
    if (volumeSink && volumeSink.audio) volumeSink.audio.muted = !volumeSink.audio.muted
  }

  function toggleInputMute() {
    if (source && source.audio) source.audio.muted = !source.audio.muted
  }

  function toggleAllMuted() {
    var mute = anyAudible
    if (hasOutput) volumeSink.audio.muted = mute
    if (hasInput) source.audio.muted = mute
  }

  function setDefaultSink(node) {
    if (!node) return
    Pipewire.preferredDefaultAudioSink = node
    if (node.id !== undefined && node.name) {
      Quickshell.execDetached([
        "omarchy-audio-output-set-default",
        String(node.id),
        String(node.name)
      ])
    }
  }

  function setDefaultSource(node) {
    if (!node) return
    Pipewire.preferredDefaultAudioSource = node
    if (node.id !== undefined && node.name) {
      Quickshell.execDetached([
        "omarchy-audio-input-set-default",
        String(node.id),
        String(node.name)
      ])
    }
  }

  function sinkAvailable(node) {
    if (!node || !node.name || !sinkAvailabilityLoaded) return true
    var name = String(node.name)
    return sinkAvailability[name] !== false
  }

  function updateSinkAvailability(raw) {
    sinkAvailability = Model.parseSinkAvailability(raw)
    sinkAvailabilityLoaded = true
  }

  function loadCustomRenames(content) {
    try {
      root.customRenames = JSON.parse(String(content || "{}")) || ({})
    } catch (e) {
      root.customRenames = ({})
    }
  }

  function friendlyDeviceLabel(text) {
    return Model.friendlyDeviceLabel(text)
  }

  function nodeLabel(node) {
    return Model.nodeLabel(node, root.customRenames)
  }

  function nodeProps(node) {
    return Model.nodeProps(node)
  }

  function isHeadphones(node) {
    return Model.isHeadphones(node, root.customRenames)
  }

  function sinkGlyph(node) {
    return Model.sinkGlyph(node, root.customRenames)
  }

  function sourceGlyph(node) {
    return Model.sourceGlyph(node, root.customRenames)
  }

  function friendlyStreamLabel(label) {
    return Model.friendlyStreamLabel(label)
  }

  function streamLabelKey(label) {
    return Model.streamLabelKey(label)
  }

  function streamLabelIsGeneric(label) {
    return Model.streamLabelIsGeneric(label)
  }

  function rawStreamLabel(node) {
    return Model.rawStreamLabel(node)
  }

  function mprisPlayerLabel(player) {
    return Model.mprisPlayerLabel(player)
  }

  function mprisPlayerIsProxy(player) {
    return Model.mprisPlayerIsProxy(player)
  }

  function streamRepresentsMprisPlayer(streamLabel, playerLabel) {
    return Model.streamRepresentsMprisPlayer(streamLabel, playerLabel)
  }

  function mprisLabelsFor(predicate) {
    return Model.mprisLabelsFor(mprisPlayers, predicate)
  }

  function matchingMprisStreamLabel(label) {
    return Model.matchingMprisStreamLabel(label, mprisPlayers)
  }

  function unmatchedMprisStreamLabel(label) {
    return Model.unmatchedMprisStreamLabel(label, mprisPlayers, displayAudioStreams)
  }

  function streamLabel(node) {
    return Model.streamLabel(node, mprisPlayers, displayAudioStreams)
  }

  function streamRepresentsPlayer(node, player) {
    return Model.streamRepresentsPlayer(node, player, mprisPlayers, displayAudioStreams)
  }

  function refreshRoutingState() {
    if (!cardsProc.running) cardsProc.running = true
    if (!streamLinksProc.running) streamLinksProc.running = true
    if (renamesFile) renamesFile.reload()
  }

  function toggleSimultaneous() {
    Quickshell.execDetached(["omarchy-audio-routing", "toggle-simultaneous"])
    Qt.callLater(function() {
      refreshRoutingState()
      scheduleDisplayAudioModelRefresh()
    })
  }

  function toggleStreamRoute(streamNode, sinkNode) {
    if (!streamNode || !sinkNode) return
    var streamId = String(streamNode.id !== undefined ? streamNode.id : "")
    var streamName = String(streamNode.name || Model.rawStreamLabel(streamNode) || "")
    var sinkName = String(sinkNode.name || "")
    var sinkId = String(sinkNode.id !== undefined ? sinkNode.id : "")
    Quickshell.execDetached(["omarchy-audio-routing", "route-stream-to-sink", streamId, sinkName, streamName, sinkId])
    Qt.callLater(function() {
      if (!streamLinksProc.running) streamLinksProc.running = true
    })
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  PwObjectTracker { objects: root.candidateSinks }
  PwObjectTracker { objects: root.candidateSources }
  PwObjectTracker { objects: root.audioStreams }

  PwNodePeakMonitor {
    id: inputPeakMonitor
    node: root.source
    enabled: root.opened && !!root.source
  }

  Process {
    id: sinkAvailabilityProc
    command: ["omarchy-audio-sink-availability"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateSinkAvailability(text)
    }
  }

  Process {
    id: volumeSinkProc
    command: ["omarchy-audio-output-sink"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.volumeSinkName = String(text).trim()
    }
  }

  Process {
    id: cardsProc
    command: ["omarchy-audio-routing", "list-cards"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.soundCards = Model.parseCardProfiles(text)
    }
  }

  Process {
    id: streamLinksProc
    command: ["omarchy-audio-routing", "list-streams-and-links"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.streamLinks = Model.parseStreamLinks(text)
    }
  }

  FileView {
    id: renamesFile
    path: Quickshell.env("HOME") + "/.config/omarchy/audio-renames.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loadCustomRenames(text())
    onLoadFailed: root.customRenames = ({})
  }

  Timer {
    interval: 3000
    running: root.opened
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!sinkAvailabilityProc.running) sinkAvailabilityProc.running = true
      root.refreshRoutingState()
    }
  }

  Timer {
    interval: 15000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.resolveVolumeSink()
  }

  Timer {
    id: audioModelRefreshTimer
    interval: 75
    repeat: false
    onTriggered: root.refreshDisplayAudioModels()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.outputIcon()
    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggleAllMuted()
      else root.toggle()
    }

    onWheelMoved: function(delta) {
      if (!root.hasOutput) return
      var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
      root.wheelAccumulator = wheel.remainder
      if (wheel.steps === 0) return
      var volume = root.setOutputVolume(root.outputVolume + wheel.steps * 0.05)
      root.showVolumeOsd(volume)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        if (dy !== 0) root.moveCursor(dy)
        else if (dx !== 0) root.adjustVolume(dx * 0.05)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "m" || t === "M") {
          if (!root.cursorActive) return
          if (root.focusSection === "streams" && root.selectedIndex >= 0
              && root.selectedIndex < root.displayAudioStreams.length) {
            var s = root.displayAudioStreams[root.selectedIndex]
            if (s && s.audio) s.audio.muted = !s.audio.muted
          } else if (root.focusSection === "input") {
            root.toggleInputMute()
          } else {
            root.toggleOutputMute()
          }
        }
      }

      ScrollView {
        id: scrollArea
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: panelColumn.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        Binding {
          target: scrollArea.contentItem
          property: "interactive"
          value: panelColumn.implicitHeight > scrollArea.height
        }

        Column {
          id: panelColumn
          width: scrollArea.availableWidth
          spacing: Style.space(14)

          // ---------- Hero: speaker icon · title/status ----------
          Item {
            id: heroItem
            width: parent.width
            implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, powerSwitch.implicitHeight)

            Text {
              id: heroIcon
              textFormat: Text.PlainText
              text: root.outputIcon()
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
              opacity: root.outputMuted ? 0.5 : 1.0
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            ToggleSwitch {
              id: powerSwitch
              checked: root.anyAudible
              hasCursor: root.headerHasCursor
              foreground: root.bar.foreground
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              onHovered: function(on) { if (on) root.setHeaderCursor() }
              onToggled: root.toggleAllMuted()

              PanelToolTip {
                visible: powerSwitch.containsMouse
                text: root.toggleHint
                fontFamily: root.bar.fontFamily
              }
            }

            Column {
              id: heroLabels
              anchors.left: heroIcon.right
              anchors.leftMargin: Style.space(14)
              anchors.right: parent.right
              anchors.rightMargin: powerSwitch.width + Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)

              Text {
                text: "Audio"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                id: heroLabel
                textFormat: Text.PlainText
                text: root.outputVolumeName(
                  outputSlider.dragging ? outputSlider.liveValue : root.outputVolume,
                  root.outputMuted
                ).toUpperCase()
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.2
                elide: Text.ElideRight
                width: parent.width
              }
            }
          }

          // ---- Output devices ----
          PanelSeparator {
            foreground: root.bar.foreground
          }

          Column {
            width: parent.width
            spacing: Style.space(6)

            Item {
              width: parent.width
              implicitHeight: Math.max(outputHeader.implicitHeight, outputPercent.implicitHeight)

              PanelSectionHeader {
                id: outputHeader
                text: "OUTPUT"
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
              }

              Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(8)

                // Toggle individual device volume sliders
                Text {
                  visible: root.displayAudioSinks.length > 1
                  text: root.expandOutputLevels ? "󰝞 Hide levels" : "󰝝 Show levels"
                  color: outputLevelsMouse.containsMouse ? Color.accent : Qt.darker(root.bar.foreground, 1.4)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter

                  MouseArea {
                    id: outputLevelsMouse
                    anchors.fill: parent
                    anchors.margins: -Style.space(4)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expandOutputLevels = !root.expandOutputLevels
                  }
                }

                Text {
                  id: outputPercent
                  textFormat: Text.PlainText
                  text: Math.round((outputSlider.dragging ? outputSlider.liveValue : root.outputVolume) * 100) + "%"
                  color: Qt.darker(root.bar.foreground, 1.4)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                  opacity: root.outputMuted ? 0.5 : 1.0
                }
              }
            }

            // Simultaneous Playback across all devices
            Rectangle {
              visible: root.displayAudioSinks.length > 1
              width: parent.width
              height: Style.space(24)
              radius: Style.radius.sm || Style.space(3)
              property bool isSimultaneous: {
                for (var i = 0; i < root.soundCards.length; i++) {
                  if (root.soundCards[i] && root.soundCards[i].isSimultaneous) return true
                }
                return false
              }
              color: isSimultaneous ? Util.alpha(Color.accent, 0.25) : (simulMouse.containsMouse ? Util.alpha(root.bar.foreground, 0.12) : Util.alpha(root.bar.foreground, 0.05))
              border.color: isSimultaneous ? Color.accent : Util.alpha(root.bar.foreground, 0.2)
              border.width: 1

              Row {
                anchors.centerIn: parent
                spacing: Style.space(6)

                Text {
                  text: parent.parent.isSimultaneous ? "󰄬" : "󰓃"
                  color: parent.parent.isSimultaneous ? Color.accent : root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: parent.parent.isSimultaneous ? "Simultaneous Playback Active (All Devices)" : "Play on All Outputs Simultaneously"
                  color: parent.parent.isSimultaneous ? Color.accent : root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                id: simulMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleSimultaneous()
              }
            }

            CursorSurface {
              id: outputSliderRow
              width: parent.width
              height: outputSlider.implicitHeight + Style.spacing.controlGap
              hasCursor: root.cursorActive && root.focusSection === "output" && root.selectedIndex === -1
              onHasCursorChanged: if (hasCursor) root.ensureCursorVisible(outputSliderRow)
              foreground: root.bar.foreground
              outline: true

              PanelSlider {
                id: outputSlider
                bar: root.bar
                anchors.fill: parent
                anchors.leftMargin: Style.space(6)
                anchors.rightMargin: Style.space(6)
                minimum: 0
                maximum: 1
                step: 0.05
                value: root.outputVolume
                opacity: root.outputMuted ? 0.5 : 1.0
                enabled: !!root.sink

                onMoved: function(v) { root.setOutputVolume(v) }
                onRightClicked: root.toggleOutputMute()
              }

              HoverHandler {
                onHoveredChanged: if (hovered) {
                  root.cursorActive = true
                  root.focusSection = "output"
                  root.selectedIndex = -1
                }
              }
            }

            Repeater {
              model: root.displayAudioSinks

              SinkRow {
                required property var modelData
                required property int index
                width: panelColumn.width
                node: modelData
                rowIndex: index
              }
            }
          }

          // ---- Input ----
          PanelSeparator {
            visible: root.displayAudioSources.length > 0 || !!root.source
            foreground: root.bar.foreground
          }

          Column {
            width: parent.width
            spacing: Style.space(6)
            visible: root.displayAudioSources.length > 0 || !!root.source

            Item {
              width: parent.width
              implicitHeight: Math.max(microphoneHeader.implicitHeight, microphonePercent.implicitHeight)

              PanelSectionHeader {
                id: microphoneHeader
                text: "INPUT"
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
              }

              Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(8)

                // Toggle individual input gain sliders
                Text {
                  visible: root.displayAudioSources.length > 1
                  text: root.expandInputLevels ? "󰝞 Hide levels" : "󰝝 Show levels"
                  color: inputLevelsMouse.containsMouse ? Color.accent : Qt.darker(root.bar.foreground, 1.4)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter

                  MouseArea {
                    id: inputLevelsMouse
                    anchors.fill: parent
                    anchors.margins: -Style.space(4)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expandInputLevels = !root.expandInputLevels
                  }
                }

                Text {
                  id: microphonePercent
                  textFormat: Text.PlainText
                  text: Math.round((inputSlider.dragging ? inputSlider.liveValue : root.inputVolume) * 100) + "%"
                  color: Qt.darker(root.bar.foreground, 1.4)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                  opacity: root.inputMuted ? 0.5 : 1.0
                }
              }
            }

            CursorSurface {
              id: inputSliderRow
              visible: !!root.source
              width: parent.width
              height: inputControls.implicitHeight + Style.spacing.controlGap
              hasCursor: root.cursorActive && root.focusSection === "input" && root.selectedIndex === -1
              onHasCursorChanged: if (hasCursor) root.ensureCursorVisible(inputSliderRow)
              foreground: root.bar.foreground
              outline: true

              Column {
                id: inputControls
                anchors.fill: parent
                anchors.leftMargin: Style.space(6)
                anchors.rightMargin: Style.space(6)
                spacing: Style.space(5)

                PanelSlider {
                  id: inputSlider
                  bar: root.bar
                  width: parent.width
                  minimum: 0
                  maximum: 1
                  step: 0.05
                  value: root.inputVolume
                  opacity: root.inputMuted ? 0.5 : 1.0
                  enabled: !!root.source

                  onMoved: function(v) { root.setInputVolume(v) }
                  onRightClicked: root.toggleInputMute()
                }

                Rectangle {
                  width: parent.width
                  height: Math.max(Style.space(5), Style.spacing.xs)
                  color: Util.alpha(root.bar.foreground, 0.18)
                  opacity: root.inputMuted ? 0.35 : 1.0

                  Rectangle {
                    height: parent.height
                    width: parent.width * Math.max(0, Math.min(1, inputPeakMonitor.peak))
                    color: root.bar.foreground
                    Behavior on width { NumberAnimation { duration: 70 } }
                  }
                }
              }

              HoverHandler {
                onHoveredChanged: if (hovered) {
                  root.cursorActive = true
                  root.focusSection = "input"
                  root.selectedIndex = -1
                }
              }
            }

            Repeater {
              model: root.displayAudioSources

              SourceRow {
                required property var modelData
                required property int index
                width: panelColumn.width
                node: modelData
                rowIndex: index
              }
            }
          }

          // ---- Per-app streams ----
          PanelSeparator {
            visible: root.displayAudioStreams.length > 0
            foreground: root.bar.foreground
          }

          Column {
            width: parent.width
            spacing: Style.space(10)
            visible: root.displayAudioStreams.length > 0

            PanelSectionHeader {
              text: "SOURCES"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }

            Repeater {
              model: root.displayAudioStreams

              StreamRow {
                required property var modelData
                required property int index
                width: panelColumn.width
                node: modelData
                rowIndex: index
              }
            }
          }
        }
      }
    }
  }

  // ---- Reusable inline components ----

  component SinkRow: CursorSurface {
    id: sinkRow
    required property var node
    required property int rowIndex
    property bool isEditing: false
    property string editBuffer: ""

    readonly property bool isActive: root.sink && node && root.sink.id === node.id
    readonly property real sinkVolume: node && node.audio ? node.audio.volume : 0
    readonly property bool sinkMuted: node && node.audio ? node.audio.muted : false

    hasCursor: root.cursorActive && root.focusSection === "output" && root.selectedIndex === rowIndex
    onHasCursorChanged: if (hasCursor) root.ensureCursorVisible(sinkRow)
    current: isActive
    foreground: root.bar.foreground
    fill: root.hoverFill
    currentFill: root.selectedFill
    implicitHeight: sinkRow.isEditing
      ? (sinkEditRow.implicitHeight + Style.spacing.xl)
      : (sinkColumn.implicitHeight + Style.spacing.xl)

    function startEditing() {
      sinkRow.editBuffer = root.nodeLabel(sinkRow.node)
      sinkRow.isEditing = true
      Qt.callLater(function() {
        if (sinkEditField) sinkEditField.forceActiveFocus()
      })
    }

    function saveEdit() {
      var nextName = sinkRow.editBuffer.trim()
      var targetNode = sinkRow.node ? String(sinkRow.node.name || "") : ""
      sinkRow.isEditing = false
      if (nextName && targetNode) {
        var updated = Object.assign({}, root.customRenames)
        updated[targetNode] = nextName
        root.customRenames = updated
        Quickshell.execDetached(["omarchy-audio-rename", "set", targetNode, nextName, "--no-restart"])
      }
    }

    function resetEdit() {
      var targetNode = sinkRow.node ? String(sinkRow.node.name || "") : ""
      sinkRow.isEditing = false
      if (targetNode) {
        var updated = Object.assign({}, root.customRenames)
        delete updated[targetNode]
        root.customRenames = updated
        Quickshell.execDetached(["omarchy-audio-rename", "reset", targetNode, "--no-restart"])
      }
    }

    function cancelEdit() {
      sinkRow.isEditing = false
    }

    MouseArea {
      id: rowMouse
      visible: !sinkRow.isEditing
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      z: 0
      onContainsMouseChanged: if (containsMouse) {
        root.cursorActive = true
        root.focusSection = "output"
        root.selectedIndex = sinkRow.rowIndex
      }
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          sinkRow.startEditing()
        } else {
          root.setDefaultSink(sinkRow.node)
        }
      }
    }

    Column {
      id: sinkColumn
      visible: !sinkRow.isEditing
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(6)
      spacing: Style.space(4)
      z: 1

      Row {
        width: parent.width
        spacing: Style.space(8)

        Text {
          textFormat: Text.PlainText
          text: root.sinkGlyph(sinkRow.node)
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
          width: Style.space(22)
          horizontalAlignment: Text.AlignHCenter
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          textFormat: Text.PlainText
          text: root.nodeLabel(sinkRow.node)
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          font.bold: sinkRow.isActive
          elide: Text.ElideRight
          width: parent.width - Style.space(22) - Style.space(8) - (root.expandOutputLevels ? Style.space(40) : 0) - Style.space(24)
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          visible: root.expandOutputLevels && !sinkRow.isActive
          textFormat: Text.PlainText
          text: Math.round(sinkRow.sinkVolume * 100) + "%"
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          width: Style.space(36)
          horizontalAlignment: Text.AlignRight
          anchors.verticalCenter: parent.verticalCenter
          opacity: sinkRow.sinkMuted ? 0.5 : 1.0
        }

        // Rename pencil button
        Item {
          width: Style.space(20)
          height: Style.space(20)
          anchors.verticalCenter: parent.verticalCenter
          z: 2

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: "󰏫"
            color: editArea.containsMouse ? Color.accent : Qt.darker(root.bar.foreground, 1.5)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            opacity: (sinkRow.hasCursor || rowMouse.containsMouse || editArea.containsMouse) ? 1.0 : 0.3
          }

          MouseArea {
            id: editArea
            anchors.fill: parent
            anchors.margins: -Style.space(4)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
              mouse.accepted = true
              sinkRow.startEditing()
            }
          }
        }
      }

      // Discrete per-device volume slider
      PanelSlider {
        visible: root.expandOutputLevels && !sinkRow.isActive
        bar: root.bar
        width: parent.width
        minimum: 0
        maximum: 1
        step: 0.05
        value: sinkRow.sinkVolume
        opacity: sinkRow.sinkMuted ? 0.5 : 1.0

        onMoved: function(v) {
          if (sinkRow.node && sinkRow.node.audio) sinkRow.node.audio.volume = v
        }
        onRightClicked: {
          if (sinkRow.node && sinkRow.node.audio)
            sinkRow.node.audio.muted = !sinkRow.node.audio.muted
        }
      }
    }

    Row {
      id: sinkEditRow
      visible: sinkRow.isEditing
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(6)
      spacing: Style.space(4)
      z: 3

      TextField {
        id: sinkEditField
        text: sinkRow.editBuffer
        width: parent.width - Style.space(22) * 3 - Style.space(12)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        verticalPadding: Style.space(2)
        horizontalPadding: Style.space(6)
        foreground: root.bar.foreground
        accent: Color.accent
        onTextChanged: sinkRow.editBuffer = text
        onAccepted: sinkRow.saveEdit()
        Keys.onEscapePressed: sinkRow.cancelEdit()
      }

      Text {
        text: "󰄬"
        color: saveArea.containsMouse ? "#51cf66" : root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        width: Style.space(20)
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
          id: saveArea
          anchors.fill: parent
          anchors.margins: -Style.space(4)
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: sinkRow.saveEdit()
        }
      }

      Text {
        text: "󰑐"
        color: resetArea.containsMouse ? Color.accent : Qt.darker(root.bar.foreground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        width: Style.space(20)
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
          id: resetArea
          anchors.fill: parent
          anchors.margins: -Style.space(4)
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: sinkRow.resetEdit()
        }
      }

      Text {
        text: "󰅖"
        color: cancelArea.containsMouse ? "#ff6b6b" : Qt.darker(root.bar.foreground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        width: Style.space(20)
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
          id: cancelArea
          anchors.fill: parent
          anchors.margins: -Style.space(4)
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: sinkRow.cancelEdit()
        }
      }
    }
  }

  component SourceRow: CursorSurface {
    id: sourceRow
    required property var node
    required property int rowIndex
    property bool isEditing: false
    property string editBuffer: ""

    readonly property bool isActive: root.source && node && root.source.id === node.id
    readonly property real sourceVolume: node && node.audio ? node.audio.volume : 0
    readonly property bool sourceMuted: node && node.audio ? node.audio.muted : false

    hasCursor: root.cursorActive && root.focusSection === "input" && root.selectedIndex === rowIndex
    onHasCursorChanged: if (hasCursor) root.ensureCursorVisible(sourceRow)
    current: isActive
    foreground: root.bar.foreground
    fill: root.hoverFill
    currentFill: root.selectedFill
    implicitHeight: sourceRow.isEditing
      ? (srcEditRow.implicitHeight + Style.spacing.xl)
      : (sourceColumn.implicitHeight + Style.spacing.xl)

    function startEditing() {
      sourceRow.editBuffer = root.nodeLabel(sourceRow.node)
      sourceRow.isEditing = true
      Qt.callLater(function() {
        if (srcEditField) srcEditField.forceActiveFocus()
      })
    }

    function saveEdit() {
      var nextName = sourceRow.editBuffer.trim()
      var targetNode = sourceRow.node ? String(sourceRow.node.name || "") : ""
      sourceRow.isEditing = false
      if (nextName && targetNode) {
        var updated = Object.assign({}, root.customRenames)
        updated[targetNode] = nextName
        root.customRenames = updated
        Quickshell.execDetached(["omarchy-audio-rename", "set", targetNode, nextName, "--no-restart"])
      }
    }

    function resetEdit() {
      var targetNode = sourceRow.node ? String(sourceRow.node.name || "") : ""
      sourceRow.isEditing = false
      if (targetNode) {
        var updated = Object.assign({}, root.customRenames)
        delete updated[targetNode]
        root.customRenames = updated
        Quickshell.execDetached(["omarchy-audio-rename", "reset", targetNode, "--no-restart"])
      }
    }

    function cancelEdit() {
      sourceRow.isEditing = false
    }

    MouseArea {
      id: srcRowMouse
      visible: !sourceRow.isEditing
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      z: 0
      onContainsMouseChanged: if (containsMouse) {
        root.cursorActive = true
        root.focusSection = "input"
        root.selectedIndex = sourceRow.rowIndex
      }
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          sourceRow.startEditing()
        } else {
          root.setDefaultSource(sourceRow.node)
        }
      }
    }

    Column {
      id: sourceColumn
      visible: !sourceRow.isEditing
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(6)
      spacing: Style.space(4)
      z: 1

      Row {
        width: parent.width
        spacing: Style.space(8)

        Text {
          textFormat: Text.PlainText
          text: root.sourceGlyph(sourceRow.node)
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
          width: Style.space(22)
          horizontalAlignment: Text.AlignHCenter
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          textFormat: Text.PlainText
          text: root.nodeLabel(sourceRow.node)
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          font.bold: sourceRow.isActive
          elide: Text.ElideRight
          width: parent.width - Style.space(22) - Style.space(8) - (root.expandInputLevels ? Style.space(40) : 0) - Style.space(24)
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          visible: root.expandInputLevels && !sourceRow.isActive
          textFormat: Text.PlainText
          text: Math.round(sourceRow.sourceVolume * 100) + "%"
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          width: Style.space(36)
          horizontalAlignment: Text.AlignRight
          anchors.verticalCenter: parent.verticalCenter
          opacity: sourceRow.sourceMuted ? 0.5 : 1.0
        }

        // Rename pencil button
        Item {
          width: Style.space(20)
          height: Style.space(20)
          anchors.verticalCenter: parent.verticalCenter
          z: 2

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: "󰏫"
            color: srcEditArea.containsMouse ? Color.accent : Qt.darker(root.bar.foreground, 1.5)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            opacity: (sourceRow.hasCursor || srcRowMouse.containsMouse || srcEditArea.containsMouse) ? 1.0 : 0.3
          }

          MouseArea {
            id: srcEditArea
            anchors.fill: parent
            anchors.margins: -Style.space(4)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
              mouse.accepted = true
              sourceRow.startEditing()
            }
          }
        }
      }

      // Discrete per-device input gain slider
      PanelSlider {
        visible: root.expandInputLevels && !sourceRow.isActive
        bar: root.bar
        width: parent.width
        minimum: 0
        maximum: 1
        step: 0.05
        value: sourceRow.sourceVolume
        opacity: sourceRow.sourceMuted ? 0.5 : 1.0

        onMoved: function(v) {
          if (sourceRow.node && sourceRow.node.audio) sourceRow.node.audio.volume = v
        }
        onRightClicked: {
          if (sourceRow.node && sourceRow.node.audio)
            sourceRow.node.audio.muted = !sourceRow.node.audio.muted
        }
      }
    }

    Row {
      id: srcEditRow
      visible: sourceRow.isEditing
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(6)
      spacing: Style.space(4)
      z: 3

      TextField {
        id: srcEditField
        text: sourceRow.editBuffer
        width: parent.width - Style.space(22) * 3 - Style.space(12)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        verticalPadding: Style.space(2)
        horizontalPadding: Style.space(6)
        foreground: root.bar.foreground
        accent: Color.accent
        onTextChanged: sourceRow.editBuffer = text
        onAccepted: sourceRow.saveEdit()
        Keys.onEscapePressed: sourceRow.cancelEdit()
      }

      Text {
        text: "󰄬"
        color: srcSaveArea.containsMouse ? "#51cf66" : root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        width: Style.space(20)
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
          id: srcSaveArea
          anchors.fill: parent
          anchors.margins: -Style.space(4)
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: sourceRow.saveEdit()
        }
      }

      Text {
        text: "󰑐"
        color: srcResetArea.containsMouse ? Color.accent : Qt.darker(root.bar.foreground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        width: Style.space(20)
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
          id: srcResetArea
          anchors.fill: parent
          anchors.margins: -Style.space(4)
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: sourceRow.resetEdit()
        }
      }

      Text {
        text: "󰅖"
        color: srcCancelArea.containsMouse ? "#ff6b6b" : Qt.darker(root.bar.foreground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        width: Style.space(20)
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
          id: srcCancelArea
          anchors.fill: parent
          anchors.margins: -Style.space(4)
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: sourceRow.cancelEdit()
        }
      }
    }
  }

  component StreamRow: CursorSurface {
    id: streamRow
    required property var node
    required property int rowIndex
    property bool isRoutingExpanded: false

    readonly property real streamVolume: node && node.audio ? node.audio.volume : 0
    readonly property bool streamMuted: node && node.audio ? node.audio.muted : false
    readonly property bool isActive: root.streamRepresentsPlayer(node, root.activeMediaPlayer)

    hasCursor: root.cursorActive && root.focusSection === "streams" && root.selectedIndex === rowIndex
    onHasCursorChanged: if (hasCursor) root.ensureCursorVisible(streamRow)
    current: isActive
    foreground: root.bar.foreground
    fill: root.hoverFill
    currentFill: root.selectedFill
    implicitHeight: streamColumn.implicitHeight + Style.spacing.xl

    Column {
      id: streamColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(6)
      spacing: Style.space(4)
      z: 1

      Row {
        width: parent.width
        spacing: Style.space(8)

        Text {
          id: streamMuteIcon
          textFormat: Text.PlainText
          text: streamRow.streamMuted ? "󰝟" : "󰕾"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
          width: Style.space(22)
          horizontalAlignment: Text.AlignHCenter
          anchors.verticalCenter: parent.verticalCenter
          opacity: streamRow.streamMuted ? 0.5 : 1.0

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (streamRow.node && streamRow.node.audio)
                streamRow.node.audio.muted = !streamRow.node.audio.muted
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          text: root.streamLabel(streamRow.node)
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          font.bold: streamRow.isActive
          elide: Text.ElideRight
          width: parent.width - streamMuteIcon.width - streamPct.width - routeBtn.width - Style.space(24)
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          id: routeBtn
          width: routeBtnText.implicitWidth + Style.space(10)
          height: Style.space(20)
          radius: Style.radius.sm || Style.space(3)
          color: streamRow.isRoutingExpanded ? Util.alpha(Color.accent, 0.35) : (routeMouse.containsMouse ? Util.alpha(root.bar.foreground, 0.15) : Util.alpha(root.bar.foreground, 0.08))
          border.color: streamRow.isRoutingExpanded ? Color.accent : "transparent"
          border.width: 1
          anchors.verticalCenter: parent.verticalCenter
          z: 3

          Text {
            id: routeBtnText
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: "󰌹 Route"
            color: streamRow.isRoutingExpanded ? Color.accent : root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          MouseArea {
            id: routeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
              mouse.accepted = true
              streamRow.isRoutingExpanded = !streamRow.isRoutingExpanded
            }
          }
        }

        Text {
          id: streamPct
          textFormat: Text.PlainText
          text: Math.round(streamRow.streamVolume * 100) + "%"
          color: Qt.darker(root.bar.foreground, 1.5)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          width: Style.space(36)
          horizontalAlignment: Text.AlignRight
          anchors.verticalCenter: parent.verticalCenter
          opacity: streamRow.streamMuted ? 0.5 : 1.0
        }
      }

      PanelSlider {
        bar: root.bar
        width: parent.width
        minimum: 0
        maximum: 1.5
        step: 0.05
        value: streamRow.streamVolume
        opacity: streamRow.streamMuted ? 0.5 : 1.0

        onMoved: function(v) {
          if (streamRow.node && streamRow.node.audio) streamRow.node.audio.volume = v
        }
        onRightClicked: {
          if (streamRow.node && streamRow.node.audio)
            streamRow.node.audio.muted = !streamRow.node.audio.muted
        }
      }

      // Dynamic stream routing destinations across listed outputs
      Column {
        width: parent.width
        visible: streamRow.isRoutingExpanded
        spacing: Style.space(4)
        z: 4

        Text {
          text: "Output Destination:"
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Flow {
          width: parent.width
          spacing: Style.space(4)

          Repeater {
            model: root.displayAudioSinks

            Rectangle {
              id: sinkChip
              required property var modelData
              readonly property bool isLinked: Model.streamIsLinkedToSink(streamRow.node, sinkChip.modelData, root.streamLinks)
              width: targetContent.implicitWidth + Style.space(12)
              height: Style.space(22)
              radius: Style.radius.sm || Style.space(3)
              color: sinkChip.isLinked ? Util.alpha(Color.accent, 0.3) : (targetMouse.containsMouse ? Util.alpha(root.bar.foreground, 0.14) : Util.alpha(root.bar.foreground, 0.06))
              border.color: sinkChip.isLinked ? Color.accent : Util.alpha(root.bar.foreground, 0.2)
              border.width: 1
              z: 5

              Row {
                id: targetContent
                anchors.centerIn: parent
                spacing: Style.space(4)

                Text {
                  text: root.sinkGlyph(sinkChip.modelData)
                  color: sinkChip.isLinked ? Color.accent : root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: root.nodeLabel(sinkChip.modelData)
                  color: sinkChip.isLinked ? root.bar.foreground : Qt.darker(root.bar.foreground, 1.2)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: sinkChip.isLinked
                  elide: Text.ElideRight
                  maximumLineCount: 1
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: sinkChip.isLinked ? "󰄬" : ""
                  color: Color.accent
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  anchors.verticalCenter: parent.verticalCenter
                  visible: sinkChip.isLinked
                }
              }

              MouseArea {
                id: targetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                z: 6
                onClicked: function(mouse) {
                  mouse.accepted = true
                  root.toggleStreamRoute(streamRow.node, sinkChip.modelData)
                }
              }
            }
          }
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
      propagateComposedEvents: true
      z: 0
      onContainsMouseChanged: if (containsMouse) {
        root.cursorActive = true
        root.focusSection = "streams"
        root.selectedIndex = streamRow.rowIndex
      }
    }
  }
}
