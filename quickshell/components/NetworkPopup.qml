import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Root

Root.ServicePopup {
    id: networkPopup

    service: Root.Network
    layerNamespace: "quickshell-network"
    panelWidth: Root.Theme.popupWidthWide

    // ─── State ───
    property int _activeTab: 0  // 0=WiFi, 1=VPN

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.spacingMedium

        // ─── Active Connections ───
        Column {
            Layout.fillWidth: true
            spacing: 2

            // "Not Connected" state
            RowLayout {
                width: parent.width
                spacing: Root.Theme.spacingSmall
                visible: Root.Network.connections.length === 0

                Text {
                    text: "󰤭"
                    font.pixelSize: 22
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.error
                }

                Text {
                    text: "Not Connected"
                    font.pixelSize: Root.Theme.fontSizeNormal
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.DemiBold
                    color: Root.Theme.on.surface
                    Layout.fillWidth: true
                }
            }

            // Connection list
            Repeater {
                model: Root.Network.connections

                RowLayout {
                    required property var modelData
                    required property int index

                    width: parent.width
                    spacing: Root.Theme.spacingSmall

                    Text {
                        text: modelData.isWifi ? Root.Network.signalIcon(Root.Network.signalStrength)
                            : modelData.isEthernet ? "󰈀" : "󰛳"
                        font.pixelSize: 18
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.primary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: modelData.name
                            font.pixelSize: Root.Theme.fontSizeNormal
                            font.family: Root.Theme.fontFamily
                            font.weight: Font.DemiBold
                            color: Root.Theme.on.surface
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.device
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            color: Root.Theme.on.surfaceVariant
                        }
                    }

                    Root.IconButton {
                        icon: "󰅖"
                        size: 28
                        iconSize: 14
                        iconColor: Root.Theme.error
                        onClicked: Root.Network.disconnectDevice(modelData.device)
                    }
                }
            }

            // Disconnected ethernet devices
            Repeater {
                model: Root.Network.disconnectedEthernets

                RowLayout {
                    required property var modelData

                    width: parent.width
                    spacing: Root.Theme.spacingSmall

                    Text {
                        text: "󰈂"
                        font.pixelSize: 18
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.outline
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "Ethernet"
                            font.pixelSize: Root.Theme.fontSizeNormal
                            font.family: Root.Theme.fontFamily
                            color: Root.Theme.outline
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData.device
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            color: Root.Theme.outline
                        }
                    }

                    Root.IconButton {
                        icon: "󰌘"
                        size: 28
                        iconSize: 14
                        iconColor: Root.Theme.primary
                        onClicked: Root.Network.connectDevice(modelData.device)
                    }
                }
            }
        }

        // Speed info
        RowLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingLarge
            visible: Root.Network.connected

            RowLayout {
                spacing: Root.Theme.spacingTiny
                Text {
                    text: "󰇚"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.success
                }
                Text {
                    text: Root.Network.downloadSpeedText
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.on.surfaceVariant
                }
            }

            RowLayout {
                spacing: Root.Theme.spacingTiny
                Text {
                    text: "󰕒"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.caution
                }
                Text {
                    text: Root.Network.uploadSpeedText
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.on.surfaceVariant
                }
            }

            RowLayout {
                spacing: Root.Theme.spacingTiny
                visible: Root.Network.isWiFi && Root.Network.signalStrength >= 0
                Text {
                    text: "Signal"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.on.surfaceVariant
                }
                Text {
                    text: Root.Network.signalStrength + "%"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.DemiBold
                    color: Root.Theme.on.surface
                }
            }
        }

        // ─── Divider ───
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Root.Theme.outlineVariant
            opacity: 0.5
        }

        // ─── Tab Bar ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: ["WiFi", "VPN"]

                Rectangle {
                    required property string modelData
                    required property int index

                    Layout.fillWidth: true
                    height: 28
                    radius: Root.Theme.borderRadiusSmall
                    color: networkPopup._activeTab === index ? Root.Theme.primary
                        : tabMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"
                    Behavior on color { Root.CAnim {} }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.family: Root.Theme.fontFamily
                        font.weight: Font.DemiBold
                        color: networkPopup._activeTab === index ? Root.Theme.on.primary
                            : Root.Theme.on.surfaceVariant
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            networkPopup._activeTab = index
                            if (index === 1 && Root.Network.protonAvailable && !Root.Network._protonCountriesFetched)
                                Root.Network.fetchProtonCountries()
                        }
                    }
                }
            }
        }

        // ─── Tab Content ───
        Root.NetworkWifiTab {
            Layout.fillWidth: true
            visible: networkPopup._activeTab === 0
        }

        Root.NetworkVpnTab {
            Layout.fillWidth: true
            visible: networkPopup._activeTab === 1
        }
    }
}
