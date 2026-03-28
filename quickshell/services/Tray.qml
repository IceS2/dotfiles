pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "utils.js" as Utils
import "modals.js" as Modals

QtObject {
    id: root

    // ─── Popup (icon grid) ───
    property bool popupVisible: false

    // ─── Context menu (per-item) ───
    property bool menuVisible: false
    property var menuItem: null

    // Follow focused monitor
    property var activeScreen: Quickshell.screens[0]
    property var _focusedMonitor: Hyprland.focusedMonitor
    on_FocusedMonitorChanged: {
        activeScreen = Utils.findFocusedScreen(Hyprland, Quickshell, activeScreen)
    }

    // Screen x-coordinates (separate so menu doesn't shift the popup)
    property real popupAnchorX: -1
    property real menuAnchorX: -1

    // ─── Popup controls ───

    function togglePopup() {
        if (root.popupVisible) {
            hidePopup()
        } else {
            showPopup()
        }
    }

    function showPopup() {
        Modals.closeOthers("tray")
        root.menuVisible = false
        root.popupVisible = true
    }

    function hidePopup() {
        root.menuVisible = false
        root.popupVisible = false
    }

    // ─── Menu controls ───

    function showMenu(item, screenX) {
        Modals.closeOthers("tray")
        root.menuItem = item
        root.menuAnchorX = screenX
        root.menuVisible = true
    }

    function hideMenu() {
        root.menuVisible = false
    }

    function toggleMenu(item, screenX) {
        if (root.menuVisible && root.menuItem === item) {
            hideMenu()
        } else {
            showMenu(item, screenX)
        }
    }

    // ─── Close everything ───

    function hide() {
        root.popupVisible = false
        root.menuVisible = false
    }

    Component.onCompleted: {
        var self = root
        Modals.register("tray",
            function() { return self.popupVisible || self.menuVisible },
            function() { self.hide() }
        )
    }
}
