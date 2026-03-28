import QtQuick
import Quickshell.Io

/**
 * VPN management — WireGuard, ProtonVPN, NM VPN connections.
 * Instantiated by Network.qml (not a singleton).
 */
QtObject {
    id: root

    required property QtObject networkRoot

    // ─── WireGuard (wg-quick@wg0) ───
    property bool wgQuickActive: false

    property Process _wgCheckProc: Process {
        running: true
        command: ["systemctl", "is-active", "wg-quick@wg0"]
        stdout: SplitParser {
            onRead: data => {
                root.wgQuickActive = data.trim() === "active"
            }
        }
        onExited: (code, status) => {
            root.wgQuickActive = (code === 0)
        }
    }

    property Process _wgToggleProc: Process {
        running: false
        command: []
        onExited: (code, status) => {
            root._wgCheckProc.running = true
            root.networkRoot.statusProcess.running = true
        }
    }

    function toggleWgQuick() {
        var action = root.wgQuickActive ? "stop" : "start"
        root._wgToggleProc.command = ["pkexec", "systemctl", action, "wg-quick@wg0"]
        root._wgToggleProc.running = true
    }

    function checkWgQuick() {
        root._wgCheckProc.running = true
    }

    // ─── Active VPN State (set by Network.statusProcess) ───
    property string name: ""
    property string type: ""
    property string device: ""
    property string country: ""
    property bool connected: false

    readonly property string statusText: {
        if (networkRoot.checking) return "Checking..."
        if (!connected || !name) return "No VPN"
        if (country) return country
        if (name.toLowerCase().includes("vpn") ||
            name.toLowerCase().includes("connection") ||
            name.toLowerCase().includes("proton")) {
            return type
        }
        return name
    }

    readonly property string icon: {
        if (networkRoot.checking) return "󰦝"
        if (!connected) return "󰦞"
        return "󰦝"
    }

    // Called by Network.statusProcess.onExited to process VPN data
    function processActiveConnections(tempVpnConnections) {
        if (!tempVpnConnections || tempVpnConnections.length === 0) {
            root.connected = false
            root.name = ""
            root.type = ""
            root.device = ""
            root.country = ""
        } else {
            var vpn = tempVpnConnections[0]
            var cleanName = vpn.name.replace(/\\\\/g, '\\')
            root.name = cleanName
            root.type = root.networkRoot.getVpnTypeName(vpn.type)
            root.device = vpn.device
            root.country = root.networkRoot.extractCountry(cleanName)
            root.connected = true
        }
    }

    // ─── VPN Disconnect (active VPN) ───
    property Process disconnectProcess: Process {
        running: false
        command: []

        onExited: (code, status) => {
            root.networkRoot.statusProcess.running = true
            root.listConnections()
        }
    }

    function disconnect() {
        if (!root.connected || !root.name) return
        // Use protonvpn disconnect for ProtonVPN (handles killswitch cleanup)
        if (root.name.toLowerCase().includes("proton") || root.type === "ProtonVPN") {
            root.protonDisconnect()
        } else {
            disconnectProcess.command = ["nmcli", "connection", "down", root.name]
            disconnectProcess.running = true
        }
    }

    // ─── VPN Details ───
    property var _detailsBuffer: []

    property Process detailsProcess: Process {
        running: false
        command: ["protonvpn-cli", "status"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                if (!root._detailsBuffer) root._detailsBuffer = []
                root._detailsBuffer.push(data.trim())
            }
        }

        onExited: (code, status) => {
            if (code === 0 && root._detailsBuffer && root._detailsBuffer.length > 0) {
                var ip = ""
                var server = ""
                var protocol = ""

                for (var i = 0; i < root._detailsBuffer.length; i++) {
                    var line = root._detailsBuffer[i]
                    if (line.includes("IP:")) {
                        ip = line.split("IP:")[1]?.trim() || ""
                    } else if (line.includes("Server:")) {
                        server = line.split("Server:")[1]?.trim() || ""
                    } else if (line.includes("Protocol:")) {
                        protocol = line.split("Protocol:")[1]?.trim() || ""
                    }
                }

                var title = "VPN Connected - " + (root.country || root.type)
                var message = [
                    server ? "Server: " + server : "",
                    ip ? "IP: " + ip : "",
                    protocol ? "Protocol: " + protocol : "",
                    "Connection: " + root.name
                ].filter(function(l) { return l }).join("\n")

                root._notifyProcess.command = ["notify-send", "-t", "5000", "-i", "network-vpn", title, message]
                root._notifyProcess.running = true
            }

            root._detailsBuffer = []
        }

        onStarted: {
            root._detailsBuffer = []
        }
    }

    property Process _notifyProcess: Process {
        running: false
        command: []
    }

    function showDetails() {
        if (!root.connected) return
        root.detailsProcess.running = true
    }

    // ─── ProtonVPN Integration ───

    property bool protonAvailable: false
    property var protonCountries: []
    property bool protonFetching: false
    property bool protonConnecting: false
    property string protonConnectingCountry: ""
    property string protonError: ""
    property bool protonSuccess: false

    property Timer _clearProtonFeedbackTimer: Timer {
        interval: 3000
        onTriggered: {
            root.protonError = ""
            root.protonSuccess = false
        }
    }

    // Check if protonvpn CLI exists
    property Process _protonCheckProc: Process {
        running: true
        command: ["which", "protonvpn"]
        onExited: (code, status) => {
            root.protonAvailable = (code === 0)
        }
    }

    // Fetch country list (once per session)
    property var _protonCountryBuffer: []
    property bool _protonCountriesFetched: false

    property Process _protonCountriesProc: Process {
        running: false
        command: ["protonvpn", "countries", "list"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "" || data.startsWith("--") || data.startsWith("Country") || data.startsWith("Server")) return
                root._protonCountryBuffer.push(data)
            }
        }

        onStarted: {
            root._protonCountryBuffer = []
            root.protonFetching = true
        }

        onExited: (code, status) => {
            root.protonFetching = false
            if (code !== 0) { root._protonCountryBuffer = []; return }

            var result = []
            for (var i = 0; i < root._protonCountryBuffer.length; i++) {
                var line = root._protonCountryBuffer[i].trim()
                if (!line) continue
                // Parse: "Country Name            CODE"
                var match = line.match(/^(.+?)\s{2,}([A-Z]{2})$/)
                if (match) {
                    result.push({
                        name: match[1].trim(),
                        code: match[2]
                    })
                }
            }

            result.sort(function(a, b) { return a.name.localeCompare(b.name) })
            root.protonCountries = result
            root._protonCountriesFetched = true
            root._protonCountryBuffer = []
        }
    }

    function fetchProtonCountries() {
        if (root._protonCountriesFetched || root.protonFetching) return
        root._protonCountriesProc.running = true
    }

    // ProtonVPN connect
    property var _protonConnectOutput: []

    property Process _protonConnectProc: Process {
        running: false
        command: []

        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim() !== "")
                    root._protonConnectOutput.push(data.trim())
            }
        }

        onStarted: { root._protonConnectOutput = [] }

        onExited: (code, status) => {
            root.protonConnecting = false

            if (code === 0) {
                root.protonSuccess = true
                root.protonError = ""
            } else {
                root.protonSuccess = false
                var output = root._protonConnectOutput.join(" ")
                if (output.includes("credentials") || output.includes("sign"))
                    root.protonError = "Not signed in to ProtonVPN"
                else if (output.includes("timeout"))
                    root.protonError = "Connection timed out"
                else
                    root.protonError = "ProtonVPN connection failed"
            }

            root._protonConnectOutput = []
            root._clearProtonFeedbackTimer.restart()
            root.networkRoot.statusProcess.running = true
            root.listConnections()
        }
    }

    function protonConnect(countryCode) {
        root.protonConnecting = true
        root.protonConnectingCountry = countryCode
        root.protonError = ""
        root.protonSuccess = false
        root._protonConnectProc.command = ["protonvpn", "connect", "--country", countryCode]
        root._protonConnectProc.running = true
    }

    // ProtonVPN disconnect
    property Process _protonDisconnectProc: Process {
        running: false
        command: ["protonvpn", "disconnect"]

        onExited: (code, status) => {
            root.networkRoot.statusProcess.running = true
            root.listConnections()
        }
    }

    function protonDisconnect() {
        root._protonDisconnectProc.running = true
    }

    // ─── VPN Connections List ───

    property var connections: []
    property bool vpnConnecting: false
    property string connectingName: ""
    property string connectError: ""
    property bool connectSuccess: false

    property Timer _clearVpnFeedbackTimer: Timer {
        interval: 3000
        onTriggered: {
            root.connectError = ""
            root.connectSuccess = false
        }
    }

    property var _listBuffer: []

    property Process _listProc: Process {
        running: false
        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                root._listBuffer.push(data)
            }
        }

        onStarted: { root._listBuffer = [] }

        onExited: (code, status) => {
            if (code !== 0) { root._listBuffer = []; return }

            var result = []
            for (var i = 0; i < root._listBuffer.length; i++) {
                var parts = root._listBuffer[i].split(':')
                if (parts.length < 3) continue
                var name = parts[0]
                var type = parts[1]
                var active = parts[2] === "yes"

                if (root.networkRoot.isVpnType(type)) {
                    result.push({
                        name: name.replace(/\\\\/g, '\\').replace(/\\:/g, ':'),
                        type: root.networkRoot.getVpnTypeName(type),
                        active: active
                    })
                }
            }

            // Sort: active first, then alphabetical
            result.sort(function(a, b) {
                if (a.active !== b.active) return a.active ? -1 : 1
                return a.name.localeCompare(b.name)
            })

            root.connections = result
            root._listBuffer = []
        }
    }

    function listConnections() {
        if (!root._listProc.running)
            root._listProc.running = true
    }

    // ─── VPN Connect/Disconnect by Name ───

    property var _connectOutputLines: []

    property Process _connectProc: Process {
        running: false
        command: []

        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim() !== "")
                    root._connectOutputLines.push(data.trim())
            }
        }

        onStarted: { root._connectOutputLines = [] }

        onExited: (code, status) => {
            root.vpnConnecting = false

            if (code === 0) {
                root.connectSuccess = true
                root.connectError = ""
            } else {
                root.connectSuccess = false
                var output = root._connectOutputLines.join(" ")
                if (output.includes("timeout"))
                    root.connectError = "Connection timed out"
                else if (output.includes("not valid") || output.includes("not found"))
                    root.connectError = "Connection not found"
                else
                    root.connectError = "VPN connection failed"
            }

            root._connectOutputLines = []
            root._clearVpnFeedbackTimer.restart()

            // Refresh
            root.networkRoot.statusProcess.running = true
            root.listConnections()
        }
    }

    function connectByName(name) {
        root.vpnConnecting = true
        root.connectingName = name
        root.connectError = ""
        root.connectSuccess = false
        root._connectProc.command = ["nmcli", "connection", "up", name]
        root._connectProc.running = true
    }

    property Process _disconnectByNameProc: Process {
        running: false
        command: []

        onExited: (code, status) => {
            root.networkRoot.statusProcess.running = true
            root.listConnections()
        }
    }

    function disconnectByName(name) {
        root._disconnectByNameProc.command = ["nmcli", "connection", "down", name]
        root._disconnectByNameProc.running = true
    }
}
