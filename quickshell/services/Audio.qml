pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

/**
 * Audio Service - Native PipeWire API
 *
 * Replaces wpctl polling with reactive Quickshell.Services.Pipewire bindings.
 * Provides device enumeration, per-app streams, and default device switching.
 */
PopupServiceBase {
    id: root
    _modalKey: "audio"

    // ─── PipeWire State ───

    property bool initializing: !Pipewire.ready

    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource

    // ─── Device Lists ───

    // Track ALL nodes so their .audio properties become available
    property var _allNodes: Pipewire.nodes.values ?? []

    property PwObjectTracker _tracker: PwObjectTracker {
        objects: root._allNodes
    }

    // Extract device key from node name (inlined for QML binding tracking).
    // "alsa_output.usb-Generic_USB_Audio-00.HiFi__Speaker__sink" → "usb-Generic_USB_Audio-00"
    // Falls back to properties["device.id"], then description prefix.
    function _extractDeviceKey(nodeName, nodeProps, nodeDesc) {
        // Try node.name: split on "." and take second segment
        if (nodeName) {
            var parts = nodeName.split(".")
            if (parts.length >= 2 && parts[1]) return parts[1]
        }
        // Try properties device.id
        if (nodeProps) {
            var did = nodeProps["device.id"]
            if (did) return "devid-" + did
        }
        // Try description prefix (everything before last space-separated word)
        if (nodeDesc) {
            var dParts = nodeDesc.split(" ")
            if (dParts.length >= 2) return "desc-" + dParts.slice(0, -1).join(" ")
        }
        return ""
    }

    // Filter sinks: one per physical device (hides disabled alternate outputs like
    // Front Headphones/Speakers on USB Audio). Default sink always included,
    // other devices show only their first sink.
    property var sinks: {
        var result = []
        var nodes = root._allNodes
        var defaultSink = Pipewire.defaultAudioSink
        var seenDevices = {}

        // Always include the default sink first
        if (defaultSink && defaultSink.audio) {
            // Inline property reads so QML tracks them
            var dk = root._extractDeviceKey(defaultSink.name, defaultSink.properties, defaultSink.description)
            if (dk) seenDevices[dk] = true
            result.push(defaultSink)
        }

        // One sink per device for remaining
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (!n.isStream && n.isSink && n.audio && n !== defaultSink) {
                var key = root._extractDeviceKey(n.name, n.properties, n.description)
                if (key && seenDevices[key]) continue
                if (key) seenDevices[key] = true
                result.push(n)
            }
        }
        return result
    }

    // Filter sources: one per physical device, and hide multi-source devices entirely
    // (e.g., USB DACs with Line Input + Microphone ports that are typically unplugged).
    // Multi-source devices only show if one of their sources is the default.
    property var sources: {
        var result = []
        var nodes = root._allNodes
        var defaultSource = Pipewire.defaultAudioSource
        var seenDevices = {}

        // First pass: count sources per device key to detect multi-source devices
        var deviceSourceCount = {}
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (!n.isStream && !n.isSink && n.audio) {
                var dk = root._extractDeviceKey(n.name, n.properties, n.description)
                if (dk) deviceSourceCount[dk] = (deviceSourceCount[dk] || 0) + 1
            }
        }

        // Always include the default source first
        if (defaultSource && defaultSource.audio) {
            var defKey = root._extractDeviceKey(defaultSource.name, defaultSource.properties, defaultSource.description)
            if (defKey) seenDevices[defKey] = true
            result.push(defaultSource)
        }

        // Other sources: skip duplicates and multi-source devices (likely unused DAC inputs)
        for (var j = 0; j < nodes.length; j++) {
            var s = nodes[j]
            if (!s.isStream && !s.isSink && s.audio && s !== defaultSource) {
                var key = root._extractDeviceKey(s.name, s.properties, s.description)
                if (key && seenDevices[key]) continue
                if (key && deviceSourceCount[key] > 1) continue
                if (key) seenDevices[key] = true
                result.push(s)
            }
        }
        return result
    }

    property var streams: {
        var result = []
        var nodes = root._allNodes
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (n.isStream && n.audio) result.push(n)
        }
        return result
    }

    // ─── Volume Properties (NaN-guarded) ───

    property int volumePercent: {
        var vol = sink?.audio?.volume ?? 0
        if (isNaN(vol)) return 0
        return Math.min(100, Math.max(0, Math.round(vol * 100)))
    }

    property bool muted: !!(sink?.audio?.muted)

    property int inputVolumePercent: {
        var vol = source?.audio?.volume ?? 0
        if (isNaN(vol)) return 0
        return Math.min(100, Math.max(0, Math.round(vol * 100)))
    }

    property bool inputMuted: !!(source?.audio?.muted)

    // ─── Volume Control ───

    function setVolume(percent) {
        if (!sink?.ready || !sink?.audio) return
        var vol = Math.max(0, Math.min(1.0, percent / 100))
        sink.audio.volume = vol
    }

    function adjustVolume(delta) {
        var newPercent = volumePercent + (delta * 100)
        setVolume(newPercent)
    }

    function toggleMute() {
        if (!sink?.ready || !sink?.audio) return
        sink.audio.muted = !sink.audio.muted
    }

    function setInputVolume(percent) {
        if (!source?.ready || !source?.audio) return
        var vol = Math.max(0, Math.min(1.0, percent / 100))
        source.audio.volume = vol
    }

    function toggleInputMute() {
        if (!source?.ready || !source?.audio) return
        source.audio.muted = !source.audio.muted
    }

    // ─── Device Switching ───

    function setSink(node) {
        Pipewire.preferredDefaultAudioSink = node
    }

    function setSource(node) {
        Pipewire.preferredDefaultAudioSource = node
    }

    // ─── Stream Volume Control ───

    function setStreamVolume(node, percent) {
        if (!node?.ready || !node?.audio) return
        node.audio.volume = Math.max(0, Math.min(1.0, percent / 100))
    }

    function toggleStreamMute(node) {
        if (!node?.ready || !node?.audio) return
        node.audio.muted = !node.audio.muted
    }

    // ─── Helpers ───

    function nodeName(node) {
        if (!node) return ""
        return node.description || node.nickname || node.name || ""
    }

    function streamAppName(node) {
        if (!node) return ""
        var props = node.properties
        if (props) {
            if (props["application.name"]) return props["application.name"]
            if (props["media.name"]) return props["media.name"]
        }
        return node.description || node.name || "Unknown"
    }

    function streamAppIcon(node) {
        if (!node?.properties) return ""
        return node.properties["application.icon-name"] || ""
    }

    readonly property string volumeIcon: {
        if (muted || volumePercent === 0) return "󰝟"
        if (volumePercent < 33) return "󰕿"
        if (volumePercent < 66) return "󰖀"
        return "󰕾"
    }

    readonly property string inputIcon: {
        if (inputMuted || inputVolumePercent === 0) return "󰍭"
        return "󰍬"
    }
}
