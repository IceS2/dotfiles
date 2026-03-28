pragma Singleton
import QtQuick
import Quickshell.Bluetooth

/**
 * Bluetooth Service - Native QuickShell Bluetooth API
 *
 * Uses Quickshell.Bluetooth (BlueZ D-Bus) for reactive device management.
 * No polling — all state changes are push-based.
 */
PopupServiceBase {
    id: root
    _modalKey: "bluetooth"

    // ─── Adapter State ───

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool hasAdapter: adapter !== null
    readonly property bool powered: hasAdapter && adapter.enabled
    readonly property bool discovering: hasAdapter && adapter.discovering

    function togglePower() {
        if (!hasAdapter) return
        adapter.enabled = !adapter.enabled
    }

    function startDiscovery() {
        if (!hasAdapter || !powered) return
        adapter.discovering = true
    }

    function stopDiscovery() {
        if (!hasAdapter) return
        adapter.discovering = false
    }

    // ─── Device State ───

    // All devices from the default adapter
    readonly property var devices: {
        if (!hasAdapter) return []
        var devs = adapter.devices?.values
        if (!devs) return []
        var result = []
        for (var i = 0; i < devs.length; i++) {
            result.push(devs[i])
        }
        // Sort: connected first, then by name
        result.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            var nameA = (a.name || a.deviceName || "").toLowerCase()
            var nameB = (b.name || b.deviceName || "").toLowerCase()
            return nameA.localeCompare(nameB)
        })
        return result
    }

    // Connected devices only (for bar widget count)
    readonly property var connectedDevices: {
        var result = []
        var devs = root.devices
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].connected) result.push(devs[i])
        }
        return result
    }

    readonly property int connectedCount: connectedDevices.length

    // ─── Device Actions ───

    function toggleDevice(device) {
        if (!device) return
        if (device.connected) device.disconnect()
        else device.connect()
    }

    function forgetDevice(device) {
        if (!device) return
        device.forget()
    }

    // ─── Icons ───

    readonly property string btIcon: {
        if (!hasAdapter) return "󰂲"
        if (!powered) return "󰂲"
        if (connectedCount > 0) return "󰂱"
        return "󰂯"
    }

    function deviceIcon(device) {
        if (!device) return "󰂯"
        var icon = device.icon || ""
        if (icon.includes("audio-headset") || icon.includes("audio-headphones")) return "󰋋"
        if (icon.includes("audio")) return "󰓃"
        if (icon.includes("input-keyboard")) return "󰌌"
        if (icon.includes("input-mouse")) return "󰍽"
        if (icon.includes("input-gaming")) return "󰊖"
        if (icon.includes("input-tablet")) return "󰓶"
        if (icon.includes("phone")) return "󰏲"
        if (icon.includes("computer")) return "󰍹"
        return "󰂯"
    }
}
