import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".." as Root

Item {
    id: root
    property var toplevel
    property var windowData
    property var monitorData
    property var scale
    property var availableWorkspaceWidth
    property var availableWorkspaceHeight
    property real initX: Math.max(((windowData?.at[0] ?? 0) - (monitorData?.x ?? 0) - (monitorData?.reserved?.[0] ?? 0)) * root.scale, 0) + xOffset
    property real initY: Math.max(((windowData?.at[1] ?? 0) - (monitorData?.y ?? 0) - (monitorData?.reserved?.[1] ?? 0)) * root.scale, 0) + yOffset
    property real xOffset: 0
    property real yOffset: 0
    property int widgetMonitorId: 0

    property var targetWindowWidth: (windowData?.size[0] ?? 100) * scale
    property var targetWindowHeight: (windowData?.size[1] ?? 100) * scale
    property bool hovered: false
    property bool pressed: false

    // Monitor transform — used for icon scaling
    readonly property int monitorTransform: monitorData?.transform ?? 0

    property real iconToWindowRatio: 0.25
    property real iconToWindowRatioCompact: 0.45
    property var entry: DesktopEntries.heuristicLookup(windowData?.class)
    property string iconPath: Quickshell.iconPath(entry?.icon ?? windowData?.class ?? "application-x-executable", "image-missing")
    property bool compactMode: Root.Theme.fontSizeSmall * 4 > targetWindowHeight || Root.Theme.fontSizeSmall * 4 > targetWindowWidth

    x: initX
    y: initY
    width: Math.min((windowData?.size[0] ?? 100) * root.scale, availableWorkspaceWidth)
    height: Math.min((windowData?.size[1] ?? 100) * root.scale, availableWorkspaceHeight)
    opacity: (windowData?.monitor ?? -1) === widgetMonitorId ? 1 : 0.4

    clip: true

    Behavior on x {
        NumberAnimation {
            duration: Root.Theme.durationNormalMD3
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curveEmphasizedDecel
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: Root.Theme.durationNormalMD3
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curveEmphasizedDecel
        }
    }
    Behavior on width {
        NumberAnimation {
            duration: Root.Theme.durationNormalMD3
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curveEmphasizedDecel
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Root.Theme.durationNormalMD3
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curveEmphasizedDecel
        }
    }

    // ScreencopyView — Hyprland 0.54+ sends toplevel buffers in logical orientation
    // Gated on `capturing`, not `popupVisible`: capture must stop before the
    // panel unmaps, or captured toplevels are left frame-callback starved.
    ScreencopyView {
        anchors.fill: parent
        captureSource: Root.Overview.capturing ? root.toplevel : null
        live: true
    }

    // Overlay — outside rotation wrapper, always matches cell dimensions
    Rectangle {
        anchors.fill: parent
        radius: Root.Theme.windowRounding * root.scale
        color: root.pressed ? Root.ColorUtils.transparentize(Root.Theme.outline, 0.5) :
               root.hovered ? Root.ColorUtils.transparentize(Root.Theme.surfaceContainerHighest, 0.7) :
               Root.ColorUtils.transparentize(Root.Theme.surfaceContainerHigh)
        border.color: Root.ColorUtils.transparentize(Root.Theme.outline, 0.7)
        border.width: 1
    }

    // Window icon
    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.fontSizeSmall * 0.5

        Image {
            id: windowIcon
            property real iconSize: Math.min(root.targetWindowWidth, root.targetWindowHeight) * (root.compactMode ? root.iconToWindowRatioCompact : root.iconToWindowRatio) / (root.monitorData?.scale ?? 1)
            Layout.alignment: Qt.AlignHCenter
            source: root.iconPath
            width: iconSize
            height: iconSize
            sourceSize: Qt.size(iconSize, iconSize)

            Behavior on width {
                NumberAnimation {
                    duration: Root.Theme.durationNormalMD3
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curveEmphasizedDecel
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: Root.Theme.durationNormalMD3
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Root.Theme.curveEmphasizedDecel
                }
            }
        }
    }
}
