import QtQuick
import Quickshell
import Quickshell.Wayland
import ".." as Root

PanelWindow {
    id: toastWindow

    // ─── Layer Shell ───
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-toast"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // ─── Position: top-center ───
    anchors.top: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    mask: Region {}  // Click-through so toast doesn't block bar

    screen: Root.Toast.activeScreen

    // ─── Reactive toast triggers ───
    Connections {
        target: Root.Notifications
        function onDndChanged() {
            Root.Toast.show(
                Root.Notifications.dnd ? "󰂛" : "󰂚",
                Root.Notifications.dnd ? "Do Not Disturb" : "Notifications On")
        }
    }

    // ─── Size ───
    implicitHeight: pill.height + topMargin + 8

    // ─── Offset below bar ───
    readonly property int topMargin: Root.Theme.barHeight + Root.Theme.gapOuter

    // ─── Mode detection ───
    readonly property bool isProgress: Root.Toast.progress >= 0

    // ─── Colors ───
    readonly property color iconColor: Root.Toast.alert ? Root.Theme.error : Root.Theme.on.surface
    readonly property color accentColor: Root.Toast.alert ? Root.Theme.error : Root.Theme.secondary

    // ─── Visibility ───
    visible: Root.Toast.visible
    property bool _showing: Root.Toast.visible

    // ─── Pill ───
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: toastWindow.topMargin

        width: toastWindow.isProgress ? Root.Theme.toastProgressWidth : textContent.implicitWidth + Root.Theme.paddingLarge * 2
        height: 36
        radius: 18
        color: Root.Theme.surfaceGlass
        border.color: Root.Theme.surfaceContainer
        border.width: Root.Theme.borderWidthThin

        Behavior on width {
            NumberAnimation {
                duration: Root.Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        // Slide + fade animation
        property real slideY: toastWindow._showing ? 0 : -20
        opacity: toastWindow._showing ? 1.0 : 0.0
        transform: Translate { y: pill.slideY }

        Behavior on slideY {
            NumberAnimation {
                duration: Root.Theme.durationNormalMD3
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curveExpressiveDefaultSpatial
            }
        }

        Behavior on opacity {
            OpacityAnimator {
                duration: toastWindow._showing ? Root.Theme.durationFast : Root.Theme.durationSlow
                easing.type: Easing.OutCubic
            }
        }

        // ─── Text mode content ───
        Row {
            id: textContent
            anchors.centerIn: parent
            spacing: Root.Theme.spacingSmall
            visible: !toastWindow.isProgress

            Text {
                text: Root.Toast.icon
                font.pixelSize: Root.Theme.fontSizeNormal
                font.family: Root.Theme.fontFamily
                color: Root.Theme.on.surface
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: Root.Toast.text
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Root.Theme.fontWeight
                color: Root.Theme.on.surface
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ─── Progress mode content ───
        Row {
            id: progressContent
            anchors.fill: parent
            anchors.leftMargin: Root.Theme.paddingMedium
            anchors.rightMargin: Root.Theme.paddingMedium
            spacing: Root.Theme.spacingSmall
            visible: toastWindow.isProgress

            // Volume icon
            Text {
                text: Root.Toast.icon
                font.pixelSize: Root.Theme.iconFontSize
                font.family: Root.Theme.fontFamily
                color: toastWindow.iconColor
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color {
                    ColorAnimation { duration: Root.Theme.durationFast }
                }
            }

            // Progress bar track
            Item {
                width: parent.width - iconMetrics.width - percentText.width - Root.Theme.spacingSmall * 2
                height: 6
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: track
                    anchors.fill: parent
                    radius: 3
                    color: Root.Theme.surfaceContainerHigh
                }

                Rectangle {
                    height: parent.height
                    radius: 3
                    color: toastWindow.accentColor
                    width: Root.Toast.progress * parent.width

                    Behavior on width {
                        NumberAnimation {
                            duration: Root.Theme.durationFast
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: Root.Theme.durationFast }
                    }
                }
            }

            // Percentage text
            Text {
                id: percentText
                text: Root.Toast.text
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Root.Theme.fontWeight
                color: toastWindow.iconColor
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                width: 40

                Behavior on color {
                    ColorAnimation { duration: Root.Theme.durationFast }
                }
            }

            // Layout calculation for icon width
            TextMetrics {
                id: iconMetrics
                text: Root.Toast.icon
                font.pixelSize: Root.Theme.iconFontSize
                font.family: Root.Theme.fontFamily
            }
        }
    }
}
