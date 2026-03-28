pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "utils.js" as Utils

QtObject {
    id: root

    property string icon: ""
    property string text: ""
    property real progress: -1    // -1 = text mode, 0.0-1.0 = progress bar
    property bool alert: false    // Red accent when true (muted, error, etc.)
    property bool visible: false

    // Follow focused monitor
    property var activeScreen: Quickshell.screens[0]
    property var _focusedMonitor: Hyprland.focusedMonitor
    on_FocusedMonitorChanged: {
        activeScreen = Utils.findFocusedScreen(Hyprland, Quickshell, activeScreen)
    }

    // ─── Queuing ───
    // Stores at most 1 pending text toast (latest wins)
    property var _pendingToast: null
    property bool _isProgress: false

    property Timer _hideTimer: Timer {
        interval: 2000
        onTriggered: {
            if (root._pendingToast) {
                var pending = root._pendingToast
                root._pendingToast = null
                root._displayText(pending.icon, pending.text)
            } else {
                root.visible = false
                root._isProgress = false
            }
        }
    }

    // Minimum display time for text toasts — prevents rapid overwrites
    property Timer _minDisplayTimer: Timer {
        interval: 1500
        property bool elapsed: true
        onTriggered: elapsed = true
    }

    // Internal: display a text toast immediately
    function _displayText(icon, text) {
        root.icon = icon
        root.text = text
        root.progress = -1
        root.alert = false
        root._isProgress = false
        root.visible = true
        root._hideTimer.restart()
        root._minDisplayTimer.elapsed = false
        root._minDisplayTimer.restart()
    }

    // Text mode — respects minimum display time
    function show(icon, text) {
        // If currently showing text and min time hasn't elapsed, store as pending
        if (root.visible && !root._isProgress && !root._minDisplayTimer.elapsed) {
            root._pendingToast = { icon: icon, text: text }
            return
        }
        // If currently showing progress, store as pending (progress is time-sensitive)
        if (root.visible && root._isProgress) {
            root._pendingToast = { icon: icon, text: text }
            return
        }
        root._displayText(icon, text)
    }

    // Progress bar mode — always updates in-place (time-sensitive feedback)
    function showProgress(icon, progress, alert) {
        var clamped = Math.max(0, Math.min(1, progress || 0))
        root.icon = icon
        root.text = Math.round(clamped * 100) + "%"
        root.progress = clamped
        root.alert = alert ?? false
        root._isProgress = true
        root.visible = true
        root._hideTimer.restart()
    }
}
