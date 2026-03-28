import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.BarWidget {
    id: btWidget
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    anchorTarget: Root.Bluetooth
    anchorProperty: "anchorX"
    tintColor: Root.Theme.sky

    // Hide when no adapter available
    visible: Root.Bluetooth.hasAdapter

    readonly property bool powered: Root.Bluetooth.powered
    readonly property int connectedCount: Root.Bluetooth.connectedCount
    readonly property color iconColor: {
        if (!powered) return Root.Theme.outline
        if (connectedCount > 0) return Root.Theme.sky
        return Root.Theme.sky
    }

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            updateAnchor()
            Root.Bluetooth.togglePopup()
        } else if (mouse.button === Qt.RightButton) {
            Root.Bluetooth.togglePower()
        }
    }

    Text {
        text: Root.Bluetooth.btIcon
        font.pixelSize: Root.Theme.iconFontSize
        font.family: Root.Theme.fontFamily
        color: iconColor

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }
}
