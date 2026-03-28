pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Network Service - Connection status, WiFi signal, network speeds, and VPN
 *
 * Features:
 * - Prioritizes WiFi over Ethernet for primary connection
 * - WiFi signal strength detection
 * - Real-time upload/download speeds
 * - VPN detection and management (WireGuard, OpenVPN, ProtonVPN, etc.)
 * - WiFi scanning and connection management (for popup)
 *
 * Single nmcli poll (1s) feeds both network and VPN state.
 * WiFi and VPN management delegated to sub-objects.
 */
PopupServiceBase {
    id: root
    _modalKey: "network"

    // ─── Sub-objects ───

    property NetworkWifi wifi: NetworkWifi { networkRoot: root }
    property NetworkVpn vpn: NetworkVpn { networkRoot: root }

    function showPopup() {
        root.popupVisible = true
        scanWifi()
        listVpnConnections()
        root._deviceStatusProc.running = true
        if (root.protonAvailable && !root.vpn._protonCountriesFetched) root.fetchProtonCountries()
        if (root.deviceName) root.ipProcess.running = true
    }

    // ─── Backward-compat aliases: WiFi ───

    property alias wifiEnabled: root.wifi.enabled
    property alias wifiNetworks: root.wifi.networks
    property alias scanning: root.wifi.scanning
    property alias connecting: root.wifi.connecting
    property alias connectingSsid: root.wifi.connectingSsid
    property alias connectError: root.wifi.connectError
    property alias connectSuccess: root.wifi.connectSuccess
    property alias savedWifiConnections: root.wifi.savedConnections

    function toggleWifi() { wifi.toggle() }
    function scanWifi() { wifi.scanWifi() }
    function connectWifi(ssid, password) { wifi.connectWifi(ssid, password) }
    function fetchSavedWifi() { wifi.fetchSavedWifi() }
    function isKnownNetwork(ssid) { return wifi.isKnownNetwork(ssid) }
    function getSavedConnection(ssid) { return wifi.getSavedConnection(ssid) }
    function setWifiAutoConnect(ssid, enable) { wifi.setAutoConnect(ssid, enable) }
    function forgetWifiConnection(ssid) { wifi.forgetConnection(ssid) }
    function signalIcon(strength) { return wifi.signalIcon(strength) }

    // ─── Backward-compat aliases: VPN ───

    property alias wgQuickActive: root.vpn.wgQuickActive
    property alias vpnName: root.vpn.name
    property alias vpnType: root.vpn.type
    property alias vpnDevice: root.vpn.device
    property alias vpnCountry: root.vpn.country
    property alias vpnConnected: root.vpn.connected
    property alias vpnStatusText: root.vpn.statusText
    property alias vpnIcon: root.vpn.icon
    property alias vpnConnections: root.vpn.connections
    property alias vpnConnecting: root.vpn.vpnConnecting
    property alias vpnConnectingName: root.vpn.connectingName
    property alias vpnConnectError: root.vpn.connectError
    property alias vpnConnectSuccess: root.vpn.connectSuccess
    property alias protonAvailable: root.vpn.protonAvailable
    property alias protonCountries: root.vpn.protonCountries
    property alias protonFetching: root.vpn.protonFetching
    property alias protonConnecting: root.vpn.protonConnecting
    property alias protonConnectingCountry: root.vpn.protonConnectingCountry
    property alias protonError: root.vpn.protonError
    property alias protonSuccess: root.vpn.protonSuccess
    // Internal but accessed by NetworkPopup
    property bool _protonCountriesFetched: root.vpn._protonCountriesFetched

    function toggleWgQuick() { vpn.toggleWgQuick() }
    function vpnDisconnect() { vpn.disconnect() }
    function vpnShowDetails() { vpn.showDetails() }
    function vpnConnectByName(name) { vpn.connectByName(name) }
    function vpnDisconnectByName(name) { vpn.disconnectByName(name) }
    function protonConnect(countryCode) { vpn.protonConnect(countryCode) }
    function protonDisconnect() { vpn.protonDisconnect() }
    function fetchProtonCountries() { vpn.fetchProtonCountries() }
    function listVpnConnections() { vpn.listConnections() }

    // ─── Network connection properties ───
    property string connectionName: ""
    property string connectionType: ""
    property string deviceName: ""
    property bool connected: false
    property bool checking: true

    // All active ethernet/WiFi connections [{name, type, device, isWifi, isEthernet}]
    property var connections: []

    // WiFi signal strength (0-100, -1 if not WiFi)
    property int signalStrength: -1

    // Network speeds (bytes per second)
    property real downloadSpeed: 0
    property real uploadSpeed: 0

    // Display mode: 0=name, 1=speeds, 2=ip
    property int displayMode: 0

    // IP address
    property string ipAddress: ""

    // Internal tracking for speed calculation
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real lastSpeedUpdate: Date.now()

    readonly property bool isWiFi: _isWiFiType(connectionType)
    readonly property bool isEthernet: _isEthernetType(connectionType)

    readonly property string statusText: {
        if (checking) return "Checking..."
        if (!connected || !connectionName) return "Disconnected"
        if (isEthernet) return "Ethernet"
        if (isWiFi) return connectionName
        return connectionName || "Connected"
    }

    // ─── Shared helpers ───

    function _isWiFiType(type) {
        var t = type.toLowerCase()
        return t.includes("wireless") || t.includes("wifi") || t === "802-11-wireless"
    }

    function _isEthernetType(type) {
        var t = type.toLowerCase()
        return t.includes("ethernet") || t === "802-3-ethernet"
    }

    function formatSpeed(bytesPerSecond) {
        if (bytesPerSecond < 1024) return Math.round(bytesPerSecond) + " B/s"
        if (bytesPerSecond < 1024 * 1024) return (bytesPerSecond / 1024).toFixed(1) + " KB/s"
        return (bytesPerSecond / (1024 * 1024)).toFixed(1) + " MB/s"
    }

    readonly property string downloadSpeedText: formatSpeed(downloadSpeed)
    readonly property string uploadSpeedText: formatSpeed(uploadSpeed)

    function isVpnType(type) {
        var vpnTypes = ["vpn", "wireguard", "openvpn", "tun", "pptp", "l2tp", "ipsec"]
        return vpnTypes.some(function(vpn) { return type.toLowerCase().includes(vpn) })
    }

    function isLoopback(device) {
        return device === "lo"
    }

    function _isFilteredConnection(type, device, name) {
        var lowerType = type.toLowerCase()
        if (lowerType === "bridge" || lowerType === "loopback") return true
        if (device.startsWith("br-") || device === "docker0") return true
        if (device.startsWith("veth")) return true
        return false
    }

    function getVpnTypeName(type) {
        var lower = type.toLowerCase()
        if (lower.includes("wireguard") || lower.includes("wg")) return "WireGuard"
        if (lower.includes("openvpn")) return "OpenVPN"
        if (lower.includes("pptp")) return "PPTP"
        if (lower.includes("l2tp")) return "L2TP"
        if (lower.includes("ipsec")) return "IPSec"
        if (lower.includes("proton")) return "ProtonVPN"
        return "VPN"
    }

    function extractCountry(name) {
        var match = name.match(/ProtonVPN\s+([A-Z]{2})#\d+/i)
        if (match && match[1]) return match[1].toUpperCase()

        var codeMatch = name.match(/\b([A-Z]{2})\b/)
        if (codeMatch && codeMatch[1]) return codeMatch[1]

        return ""
    }

    // ─── Single update timer ───
    property int _tickCount: 0

    property Timer updateTimer: Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.statusProcess.running = true
            if (root.isWiFi) root.signalProcess.running = true
            if (root.deviceName && (root.displayMode === 1 || root.popupVisible)) root.updateNetworkSpeed()
            if (root.popupVisible) root._deviceStatusProc.running = true
            // Check WiFi radio + wg-quick state every 5s
            root._tickCount++
            if (root._tickCount % 5 === 0) {
                root.wifi.checkRadio()
                root.vpn.checkWgQuick()
            }
        }
    }

    // ─── nmcli process — feeds BOTH network and VPN state ───
    property var _tempConnections: []
    property var _tempVpnConnections: []

    property Process statusProcess: Process {
        running: false
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return

                var parts = data.split(':')
                if (parts.length >= 2) {
                    var name = parts[0] || ""
                    var type = parts[1] || ""
                    var device = parts[2] || ""

                    if (root.isVpnType(type)) {
                        if (!root._tempVpnConnections) root._tempVpnConnections = []
                        root._tempVpnConnections.push({ name: name, type: type, device: device })
                    } else if (!root.isLoopback(device) && !root._isFilteredConnection(type, device, name)) {
                        if (!root._tempConnections) root._tempConnections = []
                        root._tempConnections.push({ name: name, type: type, device: device })
                    }
                }
            }
        }

        onExited: (code, status) => {
            root.checking = false

            // ── Network selection ──
            if (code !== 0 || !root._tempConnections || root._tempConnections.length === 0) {
                root.connected = false
                root.connectionName = ""
                root.connectionType = ""
                root.deviceName = ""
                root.signalStrength = -1
            } else {
                // Prioritize: WiFi > Ethernet > Other
                var selectedConnection = null

                for (var i = 0; i < root._tempConnections.length; i++) {
                    if (root._isWiFiType(root._tempConnections[i].type)) {
                        selectedConnection = root._tempConnections[i]
                        break
                    }
                }

                if (!selectedConnection) {
                    for (var j = 0; j < root._tempConnections.length; j++) {
                        if (root._isEthernetType(root._tempConnections[j].type)) {
                            selectedConnection = root._tempConnections[j]
                            break
                        }
                    }
                }

                if (!selectedConnection && root._tempConnections.length > 0) {
                    selectedConnection = root._tempConnections[0]
                }

                if (selectedConnection) {
                    var deviceChanged = root.deviceName !== selectedConnection.device
                    root.connectionName = selectedConnection.name.replace(/\\\\/g, '\\')
                    root.connectionType = selectedConnection.type
                    root.deviceName = selectedConnection.device
                    root.connected = true

                    if (deviceChanged) {
                        root.lastRxBytes = 0
                        root.lastTxBytes = 0
                        root.downloadSpeed = 0
                        root.uploadSpeed = 0
                        root.lastSpeedUpdate = Date.now()
                    }

                    if (root._isWiFiType(selectedConnection.type)) {
                        root.signalProcess.running = true
                    }
                } else {
                    root.connected = false
                    root.connectionName = ""
                    root.connectionType = ""
                    root.deviceName = ""
                    root.signalStrength = -1
                }
            }

            // ── Expose all active connections ──
            var conns = []
            if (root._tempConnections && root._tempConnections.length > 0) {
                for (var k = 0; k < root._tempConnections.length; k++) {
                    var c = root._tempConnections[k]
                    conns.push({
                        name: c.name.replace(/\\\\/g, '\\'),
                        type: c.type,
                        device: c.device,
                        isWifi: root._isWiFiType(c.type),
                        isEthernet: root._isEthernetType(c.type)
                    })
                }
            }
            root.connections = conns

            // ── Delegate VPN processing ──
            root.vpn.processActiveConnections(root._tempVpnConnections)

            // Clear for next update
            root._tempConnections = []
            root._tempVpnConnections = []
        }

        onStarted: {
            root._tempConnections = []
            root._tempVpnConnections = []
        }
    }

    // ─── WiFi signal strength ───
    property Process signalProcess: Process {
        running: false
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SSID", "dev", "wifi"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return

                if (data.startsWith("*")) {
                    var parts = data.substring(1).split(':')
                    if (parts.length >= 2) {
                        var signal = parseInt(parts[1])
                        if (!isNaN(signal)) {
                            root.signalStrength = signal
                        }
                    }
                }
            }
        }
    }

    // ─── Network speed monitoring via sysfs FileView ───
    property FileView rxFile: FileView {
        path: root.deviceName ? "/sys/class/net/" + root.deviceName + "/statistics/rx_bytes" : ""
        blockLoading: true
        watchChanges: false
        preload: false
    }

    property FileView txFile: FileView {
        path: root.deviceName ? "/sys/class/net/" + root.deviceName + "/statistics/tx_bytes" : ""
        blockLoading: true
        watchChanges: false
        preload: false
    }

    function updateNetworkSpeed() {
        if (!root.deviceName || !root.connected) return

        var now = Date.now()

        rxFile.reload()
        txFile.reload()

        var rxBytes = parseInt(rxFile.text().trim())
        var txBytes = parseInt(txFile.text().trim())

        if (isNaN(rxBytes) || isNaN(txBytes)) return

        var timeDelta = (now - root.lastSpeedUpdate) / 1000
        if (timeDelta > 0 && root.lastRxBytes > 0 && root.lastTxBytes > 0) {
            root.downloadSpeed = (rxBytes - root.lastRxBytes) / timeDelta
            root.uploadSpeed = (txBytes - root.lastTxBytes) / timeDelta
        }

        root.lastRxBytes = rxBytes
        root.lastTxBytes = txBytes
        root.lastSpeedUpdate = now
    }

    function cycleDisplay() {
        root.displayMode = (root.displayMode + 1) % 3
        if (root.displayMode === 1) {
            root.lastRxBytes = 0
            root.lastTxBytes = 0
        }
        if (root.displayMode === 2 && root.deviceName) {
            root.ipProcess.running = true
        }
    }

    property Process ipProcess: Process {
        running: false
        command: ["ip", "-4", "-o", "addr", "show", root.deviceName]
        stdout: SplitParser {
            onRead: data => {
                var match = data.match(/inet\s+(\d+\.\d+\.\d+\.\d+)/)
                if (match) root.ipAddress = match[1]
            }
        }
    }

    // ─── Network icon ───
    readonly property string networkIcon: {
        if (checking) return "󰌙"
        if (!connected) return "󰤭"
        if (isEthernet) return "󰈀"

        if (isWiFi) {
            if (signalStrength < 0) return "󰤨"
            if (signalStrength < 25) return "󰤯"
            if (signalStrength < 50) return "󰤟"
            if (signalStrength < 75) return "󰤢"
            return "󰤨"
        }

        return "󰛳"
    }

    // ─── Network Disconnect ───

    property Process disconnectProcess: Process {
        running: false
        command: []

        onExited: (code, status) => {
            root.statusProcess.running = true
            root._deviceStatusProc.running = true
        }
    }

    function disconnectNetwork() {
        if (!root.deviceName) return
        root.disconnectProcess.command = ["nmcli", "device", "disconnect", root.deviceName]
        root.disconnectProcess.running = true
    }

    function disconnectDevice(device) {
        if (!device) return
        root.disconnectProcess.command = ["nmcli", "device", "disconnect", device]
        root.disconnectProcess.running = true
    }

    // ─── Disconnected Ethernet Devices ───

    property var disconnectedEthernets: []  // [{device}]
    property var _deviceBuffer: []

    property Process _deviceStatusProc: Process {
        running: false
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]

        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                root._deviceBuffer.push(data)
            }
        }

        onStarted: { root._deviceBuffer = [] }

        onExited: (code, status) => {
            if (code !== 0) { root._deviceBuffer = []; return }

            var result = []
            for (var i = 0; i < root._deviceBuffer.length; i++) {
                var parts = root._deviceBuffer[i].split(':')
                if (parts.length < 3) continue
                var device = parts[0]
                var type = parts[1]
                var state = parts[2]
                if (type === "ethernet" && state === "disconnected") {
                    result.push({ device: device })
                }
            }

            root.disconnectedEthernets = result
            root._deviceBuffer = []
        }
    }

    property Process _connectDeviceProc: Process {
        running: false
        command: []
        onExited: (code, status) => {
            root.statusProcess.running = true
            root._deviceStatusProc.running = true
        }
    }

    function connectDevice(device) {
        if (!device) return
        root._connectDeviceProc.command = ["nmcli", "device", "connect", device]
        root._connectDeviceProc.running = true
    }
}
