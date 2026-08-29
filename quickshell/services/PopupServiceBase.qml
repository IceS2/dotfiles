import QtQuick
import Quickshell
import Quickshell.Hyprland
import "utils.js" as Utils
import "modals.js" as Modals

/**
 * Base QtObject for services that manage popup state.
 *
 * Provides: popupVisible, activeScreen, anchorX, togglePopup/showPopup/hidePopup/hide.
 * Also auto-registers with modals.js for mutual exclusivity.
 *
 * Derived singletons set their own `id: root` and override `_modalKey`.
 * Services with custom showPopup() just override it — the base
 * onPopupVisibleChanged fires automatically regardless of how popupVisible is set.
 */
QtObject {
    property bool popupVisible: false
    property var activeScreen: Quickshell.screens[0]
    property real anchorX: -1

    // Override in derived service (e.g. _modalKey: "audio")
    property string _modalKey: ""

    // ─── Focused Monitor Tracking ───
    property var _focusedMonitor: Hyprland.focusedMonitor
    on_FocusedMonitorChanged: {
        activeScreen = Utils.findFocusedScreen(Hyprland, Quickshell, activeScreen)
    }

    // ─── Popup Controls ───
    function togglePopup() {
        if (popupVisible) hidePopup()
        else showPopup()
    }

    function showPopup() {
        popupVisible = true
    }

    function hidePopup() {
        popupVisible = false
    }

    function hide() {
        popupVisible = false
    }

    function updateAnchor(screen, localX) {
        activeScreen = screen
        anchorX = localX
    }

    // ─── Modal Exclusivity (reactive — works with overridden showPopup) ───
    onPopupVisibleChanged: {
        if (popupVisible && _modalKey)
            Modals.closeOthers(_modalKey)
    }

    // ─── Auto-register with modal system ───
    Component.onCompleted: {
        if (_modalKey) {
            var self = this
            Modals.register(
                _modalKey,
                function() { return self.popupVisible },
                function() { self.hidePopup() }
            )
        }
    }
}
