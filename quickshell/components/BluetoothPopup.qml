import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.ServicePopup {
    id: btPopup

    service: Root.Bluetooth
    layerNamespace: "quickshell-bluetooth"

    // Stop discovery when popup closes
    Connections {
        target: Root.Bluetooth
        function onPopupVisibleChanged() {
            if (!Root.Bluetooth.popupVisible && Root.Bluetooth.discovering)
                Root.Bluetooth.stopDiscovery()
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.spacingMedium

        // ─── Header: Power + Discovery ───
        RowLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall

            Text {
                text: Root.Bluetooth.btIcon
                font.pixelSize: 22
                font.family: Root.Theme.fontFamily
                color: Root.Bluetooth.powered ? Root.Theme.primary : Root.Theme.outline
            }

            Text {
                text: "Bluetooth"
                font.pixelSize: Root.Theme.fontSizeNormal
                font.family: Root.Theme.fontFamily
                font.weight: Font.DemiBold
                color: Root.Theme.on.surface
                Layout.fillWidth: true
            }

            // Discovery toggle
            Root.IconButton {
                icon: "󰑐"
                size: 28
                iconSize: 14
                iconColor: Root.Bluetooth.discovering ? Root.Theme.primary : Root.Theme.on.surfaceVariant
                visible: Root.Bluetooth.powered
                onClicked: {
                    if (Root.Bluetooth.discovering) Root.Bluetooth.stopDiscovery()
                    else Root.Bluetooth.startDiscovery()
                }
            }

            // Power toggle
            Rectangle {
                width: 40
                height: 22
                radius: 11
                color: Root.Bluetooth.powered ? Root.Theme.primary : Root.Theme.surfaceContainerHigh
                Behavior on color { Root.CAnim {} }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: Root.Theme.on.primary
                    x: Root.Bluetooth.powered ? parent.width - width - 2 : 2
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on x {
                        NumberAnimation { duration: Root.Theme.durationNormal; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Root.Bluetooth.togglePower()
                }
            }
        }

        // ─── Divider ───
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Root.Theme.outlineVariant
            opacity: 0.5
            visible: Root.Bluetooth.powered
        }

        // ─── Status ───
        Text {
            text: {
                if (!Root.Bluetooth.powered) return "Bluetooth is off"
                if (Root.Bluetooth.discovering) return "Scanning..."
                if (Root.Bluetooth.devices.length === 0) return "No devices"
                return "Devices"
            }
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            font.weight: Font.Bold
            color: Root.Theme.on.surfaceVariant
            visible: Root.Bluetooth.powered
        }

        // ─── Device List ───
        Column {
            Layout.fillWidth: true
            spacing: 2
            visible: Root.Bluetooth.powered && Root.Bluetooth.devices.length > 0

            Repeater {
                model: Root.Bluetooth.devices

                Rectangle {
                    required property var modelData
                    required property int index

                    width: parent.width
                    height: 44
                    radius: Root.Theme.borderRadiusSmall
                    color: devMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"
                    Behavior on color { Root.CAnim {} }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Root.Theme.paddingSmall
                        anchors.rightMargin: Root.Theme.paddingSmall
                        spacing: Root.Theme.spacingSmall

                        // Device icon
                        Text {
                            text: Root.Bluetooth.deviceIcon(modelData)
                            font.pixelSize: 18
                            font.family: Root.Theme.fontFamily
                            color: modelData.connected ? Root.Theme.primary : Root.Theme.on.surfaceVariant
                        }

                        // Name + status
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            TextEdit {
                                text: modelData.name || modelData.deviceName || "Unknown"
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamily
                                font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                                color: modelData.connected ? Root.Theme.primary : Root.Theme.on.surface
                                Layout.fillWidth: true
                                readOnly: true
                                selectByMouse: true
                                selectedTextColor: Root.Theme.on.primary
                                selectionColor: Root.Theme.primary
                            }

                            RowLayout {
                                spacing: Root.Theme.spacingSmall

                                Text {
                                    text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "Available")
                                    font.pixelSize: Root.Theme.fontSizeTiny
                                    font.family: Root.Theme.fontFamily
                                    color: modelData.connected ? Root.Theme.success : Root.Theme.outline
                                }

                                // Battery
                                Text {
                                    text: modelData.batteryAvailable
                                        ? "󰁹 " + Math.round(modelData.battery * 100) + "%" : ""
                                    font.pixelSize: Root.Theme.fontSizeTiny
                                    font.family: Root.Theme.fontFamily
                                    color: {
                                        if (!modelData.batteryAvailable) return Root.Theme.outline
                                        if (modelData.battery < 0.2) return Root.Theme.error
                                        if (modelData.battery < 0.4) return Root.Theme.caution
                                        return Root.Theme.outline
                                    }
                                    visible: modelData.batteryAvailable
                                }
                            }
                        }

                        // Connect/Disconnect toggle
                        Root.IconButton {
                            icon: modelData.connected ? "󰂲" : "󰂱"
                            size: 28
                            iconSize: 14
                            iconColor: modelData.connected ? Root.Theme.error : Root.Theme.success
                            onClicked: Root.Bluetooth.toggleDevice(modelData)
                        }
                    }

                    MouseArea {
                        id: devMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.Bluetooth.toggleDevice(modelData)
                    }
                }
            }
        }

        // Empty state when powered but no devices
        Text {
            text: Root.Bluetooth.discovering ? "Looking for devices..." : "No devices found\nTap scan to discover"
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            color: Root.Theme.outline
            visible: Root.Bluetooth.powered && Root.Bluetooth.devices.length === 0
            horizontalAlignment: Text.AlignHCenter
            width: parent ? parent.width : 0
            Layout.fillWidth: true
            topPadding: Root.Theme.spacingSmall
            bottomPadding: Root.Theme.spacingSmall
        }
    }
}
