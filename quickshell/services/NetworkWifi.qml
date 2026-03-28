import QtQuick
import Quickshell.Io

/**
 * WiFi management — scanning, connecting, saved networks, radio toggle.
 * Instantiated by Network.qml (not a singleton).
 */
QtObject {
    id: root

    required property QtObject networkRoot

    // ─── WiFi Radio State ───
    property bool enabled: true

    property Process _radioCheckProc: Process {
        running: false
        command: ["nmcli", "radio", "wifi"]
        stdout: SplitParser {
            onRead: data => {
                root.enabled = data.trim() === "enabled"
            }
        }
    }

    property Process _toggleProc: Process {
        running: false
        command: []
        onExited: (code, status) => {
            root._radioCheckProc.running = true
            root.networkRoot.statusProcess.running = true
            // Auto-scan when WiFi is turned on (command ends with "on")
            if (code === 0 && root._toggleProc.command.length > 0 &&
                root._toggleProc.command[root._toggleProc.command.length - 1] === "on") {
                root._scanDelayTimer.restart()
            }
        }
    }

    // Delay scan slightly after WiFi enable to let the radio come up
    property Timer _scanDelayTimer: Timer {
        interval: 1500
        onTriggered: root.scanWifi()
    }

    function toggle() {
        root._toggleProc.command = ["nmcli", "radio", "wifi", root.enabled ? "off" : "on"]
        root._toggleProc.running = true
    }

    function checkRadio() {
        root._radioCheckProc.running = true
    }

    // ─── WiFi Scanning ───

    property var networks: []
    property bool scanning: false

    // ─── Connection Feedback ───

    property bool connecting: false
    property string connectingSsid: ""
    property string connectError: ""
    property bool connectSuccess: false

    property Timer _clearFeedbackTimer: Timer {
        interval: 3000
        onTriggered: {
            root.connectError = ""
            root.connectSuccess = false
        }
    }

    property var _scanBuffer: []

    property Process scanProcess: Process {
        running: false
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE,BSSID", "device", "wifi", "list", "--rescan", "yes"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                root._scanBuffer.push(data)
            }
        }

        onStarted: {
            root._scanBuffer = []
            root.scanning = true
        }

        onExited: (code, status) => {
            root.scanning = false
            if (code !== 0) return

            var networks = []
            var seen = {}
            for (var i = 0; i < root._scanBuffer.length; i++) {
                var parts = root._scanBuffer[i].split(':')
                if (parts.length < 4) continue

                var ssid = (parts[0] || "").replace(/\\\\/g, '\\').replace(/\\:/g, ':')
                if (!ssid || ssid === "--") continue
                if (seen[ssid]) continue
                seen[ssid] = true

                var signal = parseInt(parts[1]) || 0
                var security = parts[2] || ""
                var inUse = parts[3] === "*"

                networks.push({
                    ssid: ssid,
                    signal: signal,
                    security: security,
                    inUse: inUse,
                    secured: security !== "" && security !== "--"
                })
            }

            // Sort: in-use first, then by signal strength
            networks.sort(function(a, b) {
                if (a.inUse !== b.inUse) return a.inUse ? -1 : 1
                return b.signal - a.signal
            })

            root.networks = networks
            root._scanBuffer = []
        }
    }

    function scanWifi() {
        if (!root.scanProcess.running)
            root.scanProcess.running = true
        root.fetchSavedWifi()
    }

    // ─── Saved WiFi Connections ───

    property var savedConnections: []  // [{name, autoconnect, uuid}]

    property var _savedBuffer: []

    property Process _savedProc: Process {
        running: false
        command: ["nmcli", "-t", "-f", "NAME,TYPE,AUTOCONNECT,UUID", "connection", "show"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                root._savedBuffer.push(data)
            }
        }

        onStarted: { root._savedBuffer = [] }

        onExited: (code, status) => {
            if (code !== 0) { root._savedBuffer = []; return }

            var result = []
            for (var i = 0; i < root._savedBuffer.length; i++) {
                var parts = root._savedBuffer[i].split(':')
                if (parts.length < 4) continue
                var type = parts[1]
                if (!root.networkRoot._isWiFiType(type)) continue
                result.push({
                    name: parts[0].replace(/\\\\/g, '\\').replace(/\\:/g, ':'),
                    autoconnect: parts[2] === "yes",
                    uuid: parts[3]
                })
            }

            root.savedConnections = result
            root._savedBuffer = []
        }
    }

    function fetchSavedWifi() {
        if (!root._savedProc.running)
            root._savedProc.running = true
    }

    function isKnownNetwork(ssid) {
        for (var i = 0; i < root.savedConnections.length; i++) {
            if (root.savedConnections[i].name === ssid) return true
        }
        return false
    }

    function getSavedConnection(ssid) {
        for (var i = 0; i < root.savedConnections.length; i++) {
            if (root.savedConnections[i].name === ssid) return root.savedConnections[i]
        }
        return null
    }

    // ─── WiFi Auto-Connect & Forget ───

    property Process _modifyProc: Process {
        running: false
        command: []
        onExited: (code, status) => {
            root.fetchSavedWifi()
        }
    }

    function setAutoConnect(ssid, enable) {
        root._modifyProc.command = ["nmcli", "connection", "modify", ssid, "connection.autoconnect", enable ? "yes" : "no"]
        root._modifyProc.running = true
    }

    property Process _forgetProc: Process {
        running: false
        command: []
        onExited: (code, status) => {
            root.fetchSavedWifi()
            root.scanWifi()
        }
    }

    function forgetConnection(ssid) {
        root._forgetProc.command = ["nmcli", "connection", "delete", ssid]
        root._forgetProc.running = true
    }

    // ─── WiFi Connect ───

    property var _connectOutputLines: []

    property Process connectProcess: Process {
        running: false
        command: []

        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim() !== "")
                    root._connectOutputLines.push(data.trim())
            }
        }

        stderr: SplitParser {
            onRead: data => {
                if (data && data.trim() !== "")
                    root._connectOutputLines.push(data.trim())
            }
        }

        onStarted: {
            root._connectOutputLines = []
        }

        onExited: (code, status) => {
            root.connecting = false

            if (code === 0) {
                root.connectSuccess = true
                root.connectError = ""
            } else {
                root.connectSuccess = false
                var output = root._connectOutputLines.join(" ")
                if (output.includes("Secrets were required") || output.includes("No suitable") || output.includes("no network"))
                    root.connectError = "Wrong password or network unavailable"
                else if (output.includes("timeout"))
                    root.connectError = "Connection timed out"
                else if (output)
                    root.connectError = output
                else
                    root.connectError = "Connection failed"
            }

            root._connectOutputLines = []
            root._clearFeedbackTimer.restart()

            // Refresh status after connect attempt
            root.networkRoot.statusProcess.running = true
            root.scanWifi()
        }
    }

    function connectWifi(ssid, password) {
        root.connecting = true
        root.connectingSsid = ssid
        root.connectError = ""
        root.connectSuccess = false

        if (password) {
            root.connectProcess.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        } else {
            root.connectProcess.command = ["nmcli", "device", "wifi", "connect", ssid]
        }
        root.connectProcess.running = true
    }

    // ─── WiFi signal icon helper ───

    function signalIcon(strength) {
        if (strength < 25) return "󰤯"
        if (strength < 50) return "󰤟"
        if (strength < 75) return "󰤢"
        return "󰤨"
    }
}
