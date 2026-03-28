import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".." as Root

PanelWindow {
    id: popupWindow

    required property var screenObj
    screen: screenObj

    // ─── Layer Shell ───
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // ─── Position: top-right ───
    anchors.top: true
    anchors.right: true
    color: "transparent"

    // ─── Size ───
    implicitWidth: Root.Theme.notificationPopupWidth
    implicitHeight: popupColumn.implicitHeight

    // ─── Visibility ───
    visible: Root.Notifications.popups.length > 0

    // ─── Margins (offset below bar, away from screen edge) ───
    margins.top: Root.Theme.barHeight + Root.Theme.gapOuter
    margins.right: Root.Theme.gapOuter

    // ─── Single timer to check all popup expiries ───
    // Skips entirely when any popup is hovered (pause-all-on-hover pattern)
    Timer {
        interval: 500
        repeat: true
        running: Root.Notifications.popups.length > 0
        onTriggered: {
            const list = Root.Notifications.popups
            if (list.some(p => p.popupExpiry === Infinity)) return

            const now = Date.now()
            for (const p of list) {
                if (!p.popupDismissed && now >= p.popupExpiry)
                    p.popupDismissed = true  // Triggers exit animation
            }
        }
    }

    // ─── Popup List ───
    ColumnLayout {
        id: popupColumn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.left: parent.left
        spacing: Root.Theme.spacingSmall

        Repeater {
            model: Root.Notifications.popups

            Item {
                id: popupDelegate
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: delegateHeight
                clip: true

                // ─── Height tracks card, collapsible on dismiss ───
                property real delegateHeight: card.implicitHeight

                // ─── Slide animation (entry + exit) ───
                property real slideX: 0

                Component.onCompleted: {
                    if (!modelData.popupAnimated) {
                        slideX = popupWindow.implicitWidth
                        slideX = 0
                        modelData.popupAnimated = true
                    }
                    modelData.lock(popupDelegate)

                    // Handle delegate recreation for already-dismissed popups
                    // (array mutation recreates all delegates, losing prior exit state)
                    if (modelData.popupDismissed) {
                        delegateHeight = 0
                        slideX = popupWindow.implicitWidth
                        exitTimer.start()
                    }
                }
                Component.onDestruction: modelData.unlock(popupDelegate)

                Behavior on slideX {
                    Root.Anim {
                        duration: Root.Theme.durationExpressiveDefaultSpatial
                        easing.bezierCurve: Root.Theme.curveExpressiveDefaultSpatial
                    }
                }

                // Height collapse — delayed so slide leads, gentle decel curve
                NumberAnimation {
                    id: collapseAnim
                    target: popupDelegate
                    property: "delegateHeight"
                    to: 0
                    duration: 800
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curveStandard
                }

                Timer {
                    id: collapseDelay
                    interval: 150
                    onTriggered: collapseAnim.start()
                }

                // ─── Exit animation: slide out, then collapse height, then remove ───
                Connections {
                    target: popupDelegate.modelData
                    function onPopupDismissedChanged() {
                        if (popupDelegate.modelData.popupDismissed) {
                            popupDelegate.slideX = popupWindow.implicitWidth
                            collapseDelay.start()
                            exitTimer.start()
                        }
                    }
                }

                Timer {
                    id: exitTimer
                    interval: 1000  // 150ms delay + 800ms collapse + margin
                    onTriggered: Root.Notifications.removePopup(popupDelegate.modelData)
                }

                Root.NotificationCard {
                    id: card
                    x: popupDelegate.slideX
                    anchors.top: parent.top
                    width: popupDelegate.width
                    notif: popupDelegate.modelData
                    isPopup: true

                    // Hover pauses/resumes ALL popups (KDE/Dunst pattern)
                    // On resume, stagger expiry so popups dismiss in sequence
                    onHoveredChanged: {
                        const list = Root.Notifications.popups
                        if (hovered) {
                            for (const p of list)
                                if (!p.popupDismissed) p.popupExpiry = Infinity
                        } else {
                            const now = Date.now()
                            for (let i = 0; i < list.length; i++) {
                                if (!list[i].popupDismissed) {
                                    const base = Root.Notifications._expiryForUrgency(list[i].urgency)
                                    list[i].popupExpiry = now + base + i * 1000
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
