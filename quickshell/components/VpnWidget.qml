import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.BarWidget {
    id: vpnWidget
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    tintColor: Root.Theme.success

    // Only visible when VPN is connected
    visible: Root.Network.vpnConnected

    readonly property bool connected: Root.Network.vpnConnected
    readonly property string statusText: Root.Network.vpnStatusText
    readonly property string vpnIcon: Root.Network.vpnIcon
    readonly property color iconColor: {
        if (Root.Network.checking) return Root.Theme.on.surfaceVariant
        if (!connected) return Root.Theme.error
        return Root.Theme.success
    }

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            Root.Network.vpnDisconnect()
        }
    }

    // VPN icon
    Text {
        text: vpnIcon
        font.pixelSize: Root.Theme.iconFontSize
        font.family: Root.Theme.fontFamily
        color: iconColor

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }

    // VPN status text
    Text {
        text: statusText
        font.pixelSize: Root.Theme.fontSizeNormal
        font.family: Root.Theme.fontFamily
        font.weight: Root.Theme.fontWeight
        color: connected ? iconColor : Root.Theme.error
        elide: Text.ElideRight
        Layout.maximumWidth: 120

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }
}
