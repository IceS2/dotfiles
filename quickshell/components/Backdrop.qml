import QtQuick
import Quickshell
import Quickshell.Wayland
import ".." as Root

PanelWindow {
    id: backdropWindow
    visible: showing

    property bool showing: false
    required property var screenObj
    property string layerNamespace: ""

    signal closeRequested()

    screen: screenObj

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: layerNamespace
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Root.Theme.scrim
        opacity: backdropWindow.visible ? 1.0 : 0.0

        Behavior on opacity {
            OpacityAnimator {
                duration: Root.Theme.durationInstant
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: backdropWindow.closeRequested()
        }
    }
}
