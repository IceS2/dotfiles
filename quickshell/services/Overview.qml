pragma Singleton
import QtQuick
import "modals.js" as Modals

QtObject {
    id: root
    property bool popupVisible: false

    // Thumbnail capture gate. Cleared the instant we start hiding — one grace
    // period BEFORE the panel unmaps — so Hyprland tears down the screencopy
    // sessions while the layer surface is still alive.
    //
    // Tearing both down in the same frame leaves the captured toplevels
    // frame-callback starved: they commit a frame, wait for a callback that
    // never comes, and sit frozen until something forces a reconfigure (e.g.
    // refocusing them). Windows on the unfocused monitor have nothing to nudge
    // them, so they stay stuck until the overview is opened again — which
    // restarts capture and briefly wakes them.
    property bool capturing: false

    // Drives PanelWindow.visible. Lags `popupVisible` on hide by the grace period.
    property bool mapped: false

    property Timer _unmapTimer: Timer {
        interval: 120
        onTriggered: root.mapped = false
    }

    onPopupVisibleChanged: {
        if (popupVisible) {
            _unmapTimer.stop();
            mapped = true;
            capturing = true;
        } else {
            capturing = false;
            _unmapTimer.restart();
        }
    }

    function showPopup() {
        Modals.closeOthers("overview")
        popupVisible = true;
    }

    function hidePopup() {
        popupVisible = false;
    }

    function togglePopup() {
        if (popupVisible) hidePopup();
        else showPopup();
    }

    Component.onCompleted: {
        var self = this
        Modals.register("overview", function() { return self.popupVisible }, function() { self.hidePopup() })
    }
}
