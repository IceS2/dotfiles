import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.BarWidget {
    id: networkWidget
    acceptedButtons: Qt.LeftButton
    anchorTarget: Root.Network
    anchorProperty: "anchorX"
    tintColor: Root.Theme.teal

    readonly property bool connected: Root.Network.connected
    readonly property bool isWiFi: Root.Network.isWiFi
    readonly property string statusText: Root.Network.statusText
    readonly property string networkIcon: Root.Network.networkIcon
    readonly property color iconColor: {
        if (Root.Network.checking) return Root.Theme.on.surfaceVariant
        if (!connected) return Root.Theme.error
        if (isWiFi && signalStrength >= 0) {
            if (signalStrength < 25) return Root.Theme.error
            if (signalStrength < 50) return Root.Theme.warning
            if (signalStrength < 75) return Root.Theme.success
            return Root.Theme.teal
        }
        return Root.Theme.teal
    }
    readonly property int signalStrength: Root.Network.signalStrength
    readonly property string downloadSpeed: Root.Network.downloadSpeedText
    readonly property string uploadSpeed: Root.Network.uploadSpeedText
    readonly property int displayMode: Root.Network.displayMode
    readonly property string ipAddress: Root.Network.ipAddress

    onClicked: {
        updateAnchor()
        Root.Network.togglePopup()
    }

    TextMetrics {
        id: speedMetrics
        font.pixelSize: Root.Theme.fontSizeSmall
        font.family: Root.Theme.fontFamilyMono
        font.weight: Root.Theme.fontWeight
        text: "999.9 MB/s"
    }

    // Network icon
    Text {
        text: networkIcon
        font.pixelSize: Root.Theme.iconFontSize
        font.family: Root.Theme.fontFamily
        color: iconColor

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }

    // Mode 0: Connection name/status
    Text {
        visible: displayMode === 0 && (!Root.Network.isEthernet || !connected)
        text: statusText
        font.pixelSize: Root.Theme.fontSizeNormal
        font.family: Root.Theme.fontFamily
        font.weight: Root.Theme.fontWeight
        color: connected ? Root.Theme.on.surface : Root.Theme.error
        elide: Text.ElideRight
        Layout.maximumWidth: 120

        Behavior on color {
            ColorAnimation { duration: Root.Theme.durationFast }
        }
    }

    // Mode 1: Download speed
    RowLayout {
        spacing: Root.Theme.spacingTiny
        visible: displayMode === 1 && connected && !Root.Network.isEthernet

        Text {
            text: "󰇚"
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            color: Root.Theme.success
        }

        Text {
            text: downloadSpeed
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamilyMono
            font.weight: Root.Theme.fontWeight
            color: Root.Theme.on.surfaceVariant
            Layout.minimumWidth: speedMetrics.width
        }
    }

    // Mode 1: Upload speed
    RowLayout {
        spacing: Root.Theme.spacingTiny
        visible: displayMode === 1 && connected && !Root.Network.isEthernet

        Text {
            text: "󰕒"
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            color: Root.Theme.caution
        }

        Text {
            text: uploadSpeed
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamilyMono
            font.weight: Root.Theme.fontWeight
            color: Root.Theme.on.surfaceVariant
            Layout.minimumWidth: speedMetrics.width
        }
    }

    // Mode 2: IP address
    Text {
        visible: displayMode === 2 && connected && !Root.Network.isEthernet
        text: ipAddress || "..."
        font.pixelSize: Root.Theme.fontSizeSmall
        font.family: Root.Theme.fontFamilyMono
        font.weight: Root.Theme.fontWeight
        color: Root.Theme.on.surface
        elide: Text.ElideRight
        Layout.maximumWidth: 150
    }
}
