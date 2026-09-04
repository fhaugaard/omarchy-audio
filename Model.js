function isPlaybackStream(node) {
  if (!node || !node.isStream) return false
  if (node.isSink === true) return true

  var mediaClass = String(node.type || "")
  return mediaClass.indexOf("Stream/Output/Audio") !== -1
    || mediaClass.indexOf("AudioOutStream") !== -1
    || mediaClass.indexOf("Output") !== -1
}

function isAudioSource(node) {
  if (!node) return false
  if (node.audio) return true

  var mediaClass = String(node.type || "")
  return mediaClass.indexOf("Audio/Source") !== -1
    || mediaClass.indexOf("AudioSource") !== -1
    || mediaClass.indexOf("Source") !== -1
}

function listSnapshot(list) {
  return list && list.slice ? list.slice() : []
}

function outputVolumeName(volume, muted) {
  if (muted) return "Muted"
  var p = Math.round(volume * 100)
  if (p === 0) return "Silenced"
  if (p >= 100) return "Concert hall"
  if (p >= 85) return "Party mode"
  if (p >= 70) return "Cranked up"
  if (p >= 50) return "Steady groove"
  if (p >= 30) return "Easy listening"
  if (p >= 15) return "Murmur"
  return "Whisper"
}

function parseSinkAvailability(raw) {
  var next = {}
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (!line) continue
    var parts = line.split("\t")
    if (parts.length >= 2) next[parts[0]] = parts[1] !== "0"
  }
  return next
}

function parseCardProfiles(raw) {
  if (!raw) return []
  try {
    var data = typeof raw === "string" ? JSON.parse(raw) : raw
    return Array.isArray(data) ? data : []
  } catch (e) {
    return []
  }
}

function parseStreamLinks(raw) {
  if (!raw) return {}
  try {
    var data = typeof raw === "string" ? JSON.parse(raw) : raw
    return (data && typeof data === "object") ? data : {}
  } catch (e) {
    return {}
  }
}

function parseRenames(raw) {
  if (!raw) return {}
  try {
    var data = typeof raw === "string" ? JSON.parse(raw) : raw
    if (Array.isArray(data)) {
      var map = {}
      for (var i = 0; i < data.length; i++) {
        var item = data[i]
        if (item && item.node_name && item.alias) {
          map[item.node_name] = item.alias
        }
      }
      return map
    }
    return (data && typeof data === "object") ? data : {}
  } catch (e) {
    return {}
  }
}

function parseMultiOutputTargets(raw) {
  if (!raw) return []
  try {
    var data = typeof raw === "string" ? JSON.parse(raw) : raw
    if (Array.isArray(data)) return data
    if (data && typeof data === "object") {
      if (Array.isArray(data.multiOutputTargets)) return data.multiOutputTargets
      if (Array.isArray(data.simultaneousSlaves)) return data.simultaneousSlaves
      if (Array.isArray(data.targets)) return data.targets
      if (Array.isArray(data.slaves)) return data.slaves
    }
    return []
  } catch (e) {
    return []
  }
}

function parseSimultaneousSlaves(raw) {
  return parseMultiOutputTargets(raw)
}

function isSinkInSimultaneous(sinkNode, targets) {
  if (!sinkNode || !targets || !Array.isArray(targets) || targets.length === 0) return false
  var name = String(sinkNode.name || "")
  for (var i = 0; i < targets.length; i++) {
    if (targets[i] === name || targets[i].indexOf(name) !== -1 || name.indexOf(targets[i]) !== -1)
      return true
  }
  return false
}

function friendlyDeviceLabel(text) {
  var label = String(text || "").trim()
  label = label.replace(/^sof-soundwire\s+/i, "")
  label = label.replace(/^built-?in audio\s+/i, "")
  label = label.replace(/\s+Output$/i, "")
  label = label.replace(/\s+Input$/i, "")
  label = label.replace(/\bMicrophones\b/g, "Microphone")
  return label
}

function nodeProps(node) {
  return node && node.ready && node.properties ? node.properties : {}
}

function isProAudioNode(node) {
  if (!node) return false
  var p = nodeProps(node)
  var name = String(node.name || p["node.name"] || "")
  var desc = String(node.description || p["node.description"] || "")
  var prof = String(p["device.profile.name"] || p["device.profile.description"] || "")
  return name.indexOf("pro-output") !== -1
    || name.indexOf("pro-input") !== -1
    || desc.indexOf("Pro Audio") !== -1
    || prof.indexOf("pro-audio") !== -1
}

function nodeLabel(node, customRenames) {
  if (!node) return "Unknown"
  var name = node.name ? String(node.name) : ""
  if (customRenames && name && customRenames[name] && String(customRenames[name]).trim()) {
    return friendlyDeviceLabel(String(customRenames[name]).trim())
  }
  var p = nodeProps(node)
  var nickname = friendlyDeviceLabel(node.nickname || node.nick || p["node.nick"] || p["device.profile.description"] || "")
  if (nickname) return nickname
  return friendlyDeviceLabel(node.description || p["node.description"] || node.name || "Unknown")
}

function isHeadphones(node, customRenames) {
  if (!node) return false
  var label = nodeLabel(node, customRenames).toLowerCase()
  if (label.indexOf("speaker") !== -1) return false
  if (label.indexOf("headphone") !== -1 || label.indexOf("headset") !== -1 || label.indexOf("earbud") !== -1) return true

  var p = nodeProps(node)
  var blob = String([
    node.name, node.description, node.nickname,
    p["device.icon-name"] || "",
    p["device.product.name"] || "",
    p["node.description"] || "",
    p["node.nick"] || ""
  ].join(" ")).toLowerCase()
  return blob.indexOf("headphone") !== -1
    || blob.indexOf("headset") !== -1
    || blob.indexOf("earbud") !== -1
    || blob.indexOf("earphone") !== -1
    || blob.indexOf("airpod") !== -1
}

function sinkGlyph(node, customRenames) {
  if (!node) return "󰓃"
  var label = nodeLabel(node, customRenames).toLowerCase()
  if (label.indexOf("optical") !== -1 || label.indexOf("spdif") !== -1 || label.indexOf("iec958") !== -1) return "󰡁"
  if (label.indexOf("speaker") !== -1) return "󰓃"
  if (label.indexOf("headphone") !== -1 || label.indexOf("headset") !== -1) return "󰋋"
  if (label.indexOf("tv") !== -1 || label.indexOf("monitor") !== -1 || label.indexOf("display") !== -1 || label.indexOf("hdmi") !== -1) return "󰍹"
  
  if (isHeadphones(node, customRenames)) return "󰋋"
  var p = nodeProps(node)
  var blob = String([
    node.name, node.description, node.nickname,
    p["device.icon-name"] || "",
    p["device.product.name"] || ""
  ].join(" ")).toLowerCase()
  if (blob.indexOf("bluetooth") !== -1) return "󰂯"
  if (blob.indexOf("hdmi") !== -1 || blob.indexOf("display") !== -1) return "󰍹"
  return "󰓃"
}

function sourceGlyph(node, customRenames) {
  if (!node) return "󰍬"
  var label = nodeLabel(node, customRenames).toLowerCase()
  if (label.indexOf("headphone") !== -1 || label.indexOf("headset") !== -1) return "󰋋"
  if (label.indexOf("webcam") !== -1 || label.indexOf("camera") !== -1) return "󰄀"

  var p = nodeProps(node)
  var blob = String([
    node.name, node.description, node.nickname,
    p["device.icon-name"] || ""
  ].join(" ")).toLowerCase()
  if (blob.indexOf("headset") !== -1) return "󰋋"
  if (blob.indexOf("bluetooth") !== -1) return "󰂯"
  if (blob.indexOf("webcam") !== -1 || blob.indexOf("camera") !== -1) return "󰄀"
  return "󰍬"
}

function friendlyStreamLabel(label) {
  label = String(label || "").trim()
  if (!label) return ""

  var known = {
    "spotify": "Spotify"
  }
  var normalized = label.toLowerCase()
  return known[normalized] || label
}

function streamLabelKey(label) {
  return String(label || "").trim().toLowerCase()
}

function streamLabelIsGeneric(label) {
  return streamLabelKey(label) === "audio-src"
}

function rawStreamLabel(node) {
  if (!node) return ""
  var p = nodeProps(node)
  return p["application.name"]
    || node.description
    || p["media.name"]
    || p["node.name"]
    || node.name
}

function mprisPlayerLabel(player) {
  if (!player) return ""
  return friendlyStreamLabel(player.identity || player.desktopEntry || "")
}

function mprisPlayerIsProxy(player) {
  var dbusName = String(player && player.dbusName || "").toLowerCase()
  var desktopEntry = String(player && player.desktopEntry || "").toLowerCase()
  return dbusName.indexOf("playerctld") !== -1 || desktopEntry === "playerctld"
}

function streamRepresentsMprisPlayer(streamLabel, playerLabel) {
  var streamKey = streamLabelKey(friendlyStreamLabel(streamLabel))
  var playerKey = streamLabelKey(playerLabel)
  if (!streamKey || !playerKey) return false
  return streamKey === playerKey
    || streamKey.indexOf(playerKey) !== -1
    || playerKey.indexOf(streamKey) !== -1
}

function mprisLabelsFor(players, predicate) {
  var values = Array.isArray(players) ? players : []
  var playingCandidates = []
  var candidates = []
  var playingProxyCandidates = []
  var proxyCandidates = []

  for (var i = 0; i < values.length; i++) {
    var player = values[i]
    if (!player) continue
    if (!player.isPlaying && !player.canPlay) continue

    var playerLabel = mprisPlayerLabel(player)
    if (!playerLabel || !predicate(playerLabel)) continue

    if (mprisPlayerIsProxy(player)) {
      if (player.isPlaying) playingProxyCandidates.push(playerLabel)
      proxyCandidates.push(playerLabel)
    } else {
      if (player.isPlaying) playingCandidates.push(playerLabel)
      candidates.push(playerLabel)
    }
  }

  if (playingCandidates.length === 1) return playingCandidates[0]
  if (playingCandidates.length === 0 && playingProxyCandidates.length === 1) return playingProxyCandidates[0]
  if (candidates.length === 1) return candidates[0]
  if (candidates.length === 0 && proxyCandidates.length === 1) return proxyCandidates[0]
  return ""
}

function matchingMprisStreamLabel(label, players) {
  if (streamLabelIsGeneric(label)) return ""
  return mprisLabelsFor(players, function(playerLabel) {
    return streamRepresentsMprisPlayer(label, playerLabel)
  })
}

function unmatchedMprisStreamLabel(label, players, streams) {
  if (!streamLabelIsGeneric(label)) return ""

  return mprisLabelsFor(players, function(playerLabel) {
    var values = Array.isArray(streams) ? streams : []
    for (var i = 0; i < values.length; i++) {
      var stream = values[i]
      var streamLabel = rawStreamLabel(stream)
      if (!streamLabelIsGeneric(streamLabel) && streamRepresentsMprisPlayer(streamLabel, playerLabel))
        return false
    }
    return true
  })
}

function streamLabel(node, players, streams) {
  if (!node) return "Stream"
  var label = rawStreamLabel(node)
  return friendlyStreamLabel(matchingMprisStreamLabel(label, players)
    || unmatchedMprisStreamLabel(label, players, streams)
    || label) || "Stream"
}

function streamGlyph(node, players, streams) {
  if (!node) return "󰕾"
  var label = streamLabel(node, players, streams).toLowerCase()
  var raw = rawStreamLabel(node).toLowerCase()
  var combined = label + " " + raw
  
  if (combined.indexOf("spotify") !== -1) return ""
  if (combined.indexOf("firefox") !== -1) return "󰈹"
  if (combined.indexOf("chrome") !== -1 || combined.indexOf("chromium") !== -1 || combined.indexOf("brave") !== -1) return "󰊯"
  if (combined.indexOf("discord") !== -1 || combined.indexOf("vesktop") !== -1) return "󰙯"
  if (combined.indexOf("steam") !== -1 || combined.indexOf("game") !== -1) return "󰊴"
  if (combined.indexOf("mpv") !== -1 || combined.indexOf("vlc") !== -1 || combined.indexOf("video") !== -1) return "󰕼"
  return "󰕾"
}

function streamRepresentsPlayer(node, player, players, streams) {
  if (!node || !player) return false
  var playerLabel = mprisPlayerLabel(player)
  if (!playerLabel) return false

  var label = rawStreamLabel(node)
  if (!streamLabelIsGeneric(label)) return streamRepresentsMprisPlayer(label, playerLabel)
  return streamRepresentsMprisPlayer(streamLabel(node, players, streams), playerLabel)
}

function streamIsLinkedToSink(streamNode, sinkNode, streamLinks) {
  if (!streamNode || !sinkNode || !streamLinks) return false
  var streamName = String(streamNode.name || "")
  var rawName = String(rawStreamLabel(streamNode) || "")
  var sinkName = String(sinkNode.name || "")
  var streamId = String(streamNode.id !== undefined ? streamNode.id : "")

  var matchKeys = [streamId, streamName, rawName]
  for (var k = 0; k < matchKeys.length; k++) {
    var key = matchKeys[k]
    if (!key) continue
    if (streamLinks.hasOwnProperty(key)) {
      var list = streamLinks[key] || []
      for (var i = 0; i < list.length; i++) {
        if (list[i] === sinkName || list[i].indexOf(sinkName) !== -1 || sinkName.indexOf(list[i]) !== -1)
          return true
      }
      return false
    }
  }

  return false
}

if (typeof module !== "undefined") {
  module.exports = {
    isPlaybackStream: isPlaybackStream,
    isAudioSource: isAudioSource,
    listSnapshot: listSnapshot,
    outputVolumeName: outputVolumeName,
    parseSinkAvailability: parseSinkAvailability,
    parseCardProfiles: parseCardProfiles,
    parseStreamLinks: parseStreamLinks,
    parseRenames: parseRenames,
    parseMultiOutputTargets: parseMultiOutputTargets,
    parseSimultaneousSlaves: parseSimultaneousSlaves,
    isSinkInSimultaneous: isSinkInSimultaneous,
    friendlyDeviceLabel: friendlyDeviceLabel,
    nodeProps: nodeProps,
    isProAudioNode: isProAudioNode,
    nodeLabel: nodeLabel,
    isHeadphones: isHeadphones,
    sinkGlyph: sinkGlyph,
    sourceGlyph: sourceGlyph,
    friendlyStreamLabel: friendlyStreamLabel,
    streamLabelKey: streamLabelKey,
    streamLabelIsGeneric: streamLabelIsGeneric,
    rawStreamLabel: rawStreamLabel,
    mprisPlayerLabel: mprisPlayerLabel,
    mprisPlayerIsProxy: mprisPlayerIsProxy,
    streamRepresentsMprisPlayer: streamRepresentsMprisPlayer,
    mprisLabelsFor: mprisLabelsFor,
    matchingMprisStreamLabel: matchingMprisStreamLabel,
    unmatchedMprisStreamLabel: unmatchedMprisStreamLabel,
    streamLabel: streamLabel,
    streamGlyph: streamGlyph,
    streamRepresentsPlayer: streamRepresentsPlayer,
    streamIsLinkedToSink: streamIsLinkedToSink
  }
}
