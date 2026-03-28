import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".." as Root

PanelWindow {
    id: popupWindow

    // ─── Public API ───
    property bool showing: false
    property string layerNamespace: ""
    property string growDirection: "down"  // "down" (height animates) or "right" (width animates)
    property real panelX: 0
    property real panelY: Root.Theme.barHeight + Root.Theme.gapOuter
    property real panelWidth: Root.Theme.popupWidthMedium
    property real panelHeight: -1  // -1 = auto from content (for "down")
    property real contentPadding: Root.Theme.paddingMedium
    property bool showBorder: true

    signal closeRequested()
    signal panelWheel(var event)

    default property alias content: contentArea.data

    // ─── Visibility: open instantly, close after exit animation ───
    visible: showing || !closeTimer.stopped

    property bool _showing: showing

    Timer {
        id: closeTimer
        property bool stopped: true
        interval: 550
        onTriggered: stopped = true
    }

    on_ShowingChanged: {
        if (!_showing) {
            closeTimer.stopped = false
            closeTimer.restart()
        }
    }

    // ─── Layer Shell ───
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: layerNamespace
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // ─── Full screen for click-outside-to-close ───
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    // ─── Keyboard shortcut ───
    Shortcut {
        sequence: "Escape"
        onActivated: popupWindow.closeRequested()
    }

    // ─── Click outside to close ───
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: popupWindow.closeRequested()
    }

    // ─── Panel container ───
    Item {
        id: panel

        // Position: "down" uses explicit x, "right" anchors to right edge
        x: growDirection === "down" ? panelX : 0
        anchors.right: growDirection === "right" ? parent.right : undefined
        anchors.rightMargin: Root.Theme.gapOuter
        y: panelY
        clip: true

        readonly property real fullHeight: growDirection === "down"
            ? contentArea.childrenRect.height + contentPadding * 2
            : (panelHeight > 0 ? panelHeight : popupWindow.height - panelY - Root.Theme.gapOuter)

        readonly property real fullWidth: panelWidth

        implicitWidth: growDirection === "right"
            ? (popupWindow._showing ? fullWidth : 0)
            : fullWidth

        implicitHeight: growDirection === "down"
            ? (popupWindow._showing ? fullHeight : 0)
            : fullHeight

        Behavior on implicitWidth {
            enabled: growDirection === "right"
            NumberAnimation {
                duration: Root.Theme.durationExpressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: popupWindow._showing
                    ? Root.Theme.curveExpressiveDefaultSpatial
                    : Root.Theme.curveEmphasized
            }
        }

        Behavior on implicitHeight {
            enabled: growDirection === "down"
            NumberAnimation {
                duration: Root.Theme.durationExpressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: popupWindow._showing
                    ? Root.Theme.curveExpressiveDefaultSpatial
                    : Root.Theme.curveEmphasized
            }
        }

        // ─── Background ───
        Rectangle {
            id: bg
            radius: Root.Theme.borderRadiusLarge
            color: Root.Theme.surfaceGlass
            border.color: popupWindow.showBorder ? Root.Theme.surfaceContainer : "transparent"
            border.width: popupWindow.showBorder ? Root.Theme.borderWidthThin : 0

            // "down": fill parent (grows with height)
            // "right": anchor right, fixed full size (revealed as container width grows)
            anchors.right: growDirection === "right" ? parent.right : undefined
            anchors.fill: growDirection === "down" ? parent : undefined
            width: growDirection === "right" ? panel.fullWidth : undefined
            height: growDirection === "right" ? parent.height : undefined

            opacity: popupWindow._showing ? 1.0 : 0.0
            Behavior on opacity {
                OpacityAnimator {
                    duration: popupWindow._showing ? Root.Theme.durationFast : 350
                    easing.type: Easing.OutCubic
                }
            }
        }

        // ─── Absorb clicks on panel + forward wheel events ───
        MouseArea {
            anchors.fill: parent
            onClicked: function(event) { event.accepted = true }
            onWheel: function(event) { popupWindow.panelWheel(event) }
        }

        // ─── Content area ───
        Item {
            id: contentArea

            // "down": anchor top/left/right with margins, height is intrinsic
            // "right": fill the bg rectangle
            anchors.fill: growDirection === "right" ? bg : undefined
            anchors.top: growDirection === "down" ? parent.top : undefined
            anchors.left: growDirection === "down" ? parent.left : undefined
            anchors.right: growDirection === "down" ? parent.right : undefined
            anchors.margins: contentPadding

            opacity: popupWindow._showing ? 1.0 : 0.0
            Behavior on opacity {
                OpacityAnimator {
                    duration: popupWindow._showing ? Root.Theme.durationFast : 350
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
