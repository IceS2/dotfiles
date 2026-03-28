pragma Singleton
import QtQuick
import Quickshell.Io
import "modals.js" as Modals

QtObject {
    id: root

    // ─── Popup State ───
    property bool popupVisible: false

    function showPopup() {
        Modals.closeOthers("power")
        popupVisible = true
    }

    function hidePopup() {
        popupVisible = false
    }

    function togglePopup() {
        if (popupVisible) hidePopup()
        else showPopup()
    }

    // ─── Power Actions ───

    property Process _powerProc: Process {
        command: ["true"]
    }

    function _exec(cmd) {
        hidePopup()
        _powerProc.command = cmd
        _powerProc.running = true
    }

    function lockScreen() {
        _exec(["hyprlock"])
    }

    function suspend() {
        _exec(["systemctl", "suspend"])
    }

    function reboot() {
        _exec(["systemctl", "reboot"])
    }

    function shutdown() {
        _exec(["systemctl", "poweroff"])
    }

    // ─── Modal Registration ───
    Component.onCompleted: {
        var self = root
        Modals.register("power", function() { return self.popupVisible }, function() { self.hidePopup() })
    }
}
