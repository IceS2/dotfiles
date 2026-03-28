import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Root

ColumnLayout {
    id: vpnTab
    spacing: Root.Theme.spacingMedium

    // ─── Internal State ───
    property string _vpnSearch: ""

    property var _filteredCountries: {
        var search = _vpnSearch.toLowerCase()
        if (!search) return Root.Network.protonCountries
        return Root.Network.protonCountries.filter(function(c) {
            return c.name.toLowerCase().includes(search) || c.code.toLowerCase().includes(search)
        })
    }

    // Reset state when popup closes
    Connections {
        target: Root.Network
        function onPopupVisibleChanged() {
            if (!Root.Network.popupVisible) {
                vpnTab._vpnSearch = ""
            }
        }
    }

    // VPN Feedback
    Rectangle {
        Layout.fillWidth: true
        height: vpnFeedbackRow.height + Root.Theme.paddingSmall * 2
        radius: Root.Theme.borderRadiusSmall
        visible: Root.Network.vpnConnecting || Root.Network.vpnConnectError !== "" || Root.Network.vpnConnectSuccess
            || Root.Network.protonConnecting || Root.Network.protonError !== "" || Root.Network.protonSuccess
        color: {
            var hasError = Root.Network.vpnConnectError !== "" || Root.Network.protonError !== ""
            var hasSuccess = Root.Network.vpnConnectSuccess || Root.Network.protonSuccess
            if (hasError) return Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.15)
            if (hasSuccess) return Qt.rgba(Root.Theme.success.r, Root.Theme.success.g, Root.Theme.success.b, 0.15)
            return Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.15)
        }

        RowLayout {
            id: vpnFeedbackRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Root.Theme.paddingSmall
            anchors.rightMargin: Root.Theme.paddingSmall
            spacing: Root.Theme.spacingSmall

            Text {
                text: {
                    var hasError = Root.Network.vpnConnectError !== "" || Root.Network.protonError !== ""
                    var hasSuccess = Root.Network.vpnConnectSuccess || Root.Network.protonSuccess
                    if (hasError) return "󰅖"
                    if (hasSuccess) return "󰄬"
                    return "󰔟"
                }
                font.pixelSize: 14
                font.family: Root.Theme.fontFamily
                color: {
                    var hasError = Root.Network.vpnConnectError !== "" || Root.Network.protonError !== ""
                    var hasSuccess = Root.Network.vpnConnectSuccess || Root.Network.protonSuccess
                    if (hasError) return Root.Theme.error
                    if (hasSuccess) return Root.Theme.success
                    return Root.Theme.primary
                }
            }

            Text {
                text: {
                    if (Root.Network.protonConnecting)
                        return "Connecting to " + Root.Network.protonConnectingCountry + "..."
                    if (Root.Network.vpnConnecting)
                        return "Connecting to " + Root.Network.vpnConnectingName + "..."
                    if (Root.Network.protonError !== "")
                        return Root.Network.protonError
                    if (Root.Network.vpnConnectError !== "")
                        return Root.Network.vpnConnectError
                    if (Root.Network.protonSuccess || Root.Network.vpnConnectSuccess)
                        return "VPN connected"
                    return ""
                }
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                color: {
                    var hasError = Root.Network.vpnConnectError !== "" || Root.Network.protonError !== ""
                    var hasSuccess = Root.Network.vpnConnectSuccess || Root.Network.protonSuccess
                    if (hasError) return Root.Theme.error
                    if (hasSuccess) return Root.Theme.success
                    return Root.Theme.on.surface
                }
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
    }

    // ─── WireGuard (wg-quick) ───
    RowLayout {
        Layout.fillWidth: true
        spacing: Root.Theme.spacingSmall

        Text {
            text: "󰖂"
            font.pixelSize: 18
            font.family: Root.Theme.fontFamily
            color: Root.Network.wgQuickActive ? Root.Theme.primary : Root.Theme.on.surfaceVariant
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "WireGuard (wg0)"
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Font.Bold
                color: Root.Theme.on.surface
            }

            Text {
                text: Root.Network.wgQuickActive ? "Active" : "Inactive"
                font.pixelSize: Root.Theme.fontSizeTiny
                font.family: Root.Theme.fontFamily
                color: Root.Network.wgQuickActive ? Root.Theme.success : Root.Theme.outline
            }
        }

        // Toggle pill
        Rectangle {
            width: 36
            height: 20
            radius: 10
            color: Root.Network.wgQuickActive ? Root.Theme.primary : Root.Theme.surfaceContainerHigh
            Behavior on color { Root.CAnim {} }

            Rectangle {
                width: 16
                height: 16
                radius: 8
                x: Root.Network.wgQuickActive ? parent.width - width - 2 : 2
                anchors.verticalCenter: parent.verticalCenter
                color: Root.Network.wgQuickActive ? Root.Theme.on.primary : Root.Theme.outline

                Behavior on x { NumberAnimation { duration: Root.Theme.durationNormal; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Root.Network.toggleWgQuick()
            }
        }
    }

    // Divider below wg-quick
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Root.Theme.outlineVariant
        opacity: 0.5
        visible: Root.Network.protonAvailable || Root.Network.vpnConnections.length > 0
    }

    // ─── ProtonVPN Section ───
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Root.Theme.spacingSmall
        visible: Root.Network.protonAvailable

        // Header + status
        RowLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall

            Text {
                text: "󰦝"
                font.pixelSize: 18
                font.family: Root.Theme.fontFamily
                color: Root.Network.vpnConnected ? Root.Theme.primary : Root.Theme.on.surfaceVariant
            }

            Text {
                text: "ProtonVPN"
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Font.Bold
                color: Root.Theme.on.surfaceVariant
                Layout.fillWidth: true
            }

            Text {
                text: Root.Network.vpnConnected ? Root.Network.vpnCountry || "Connected" : "Disconnected"
                font.pixelSize: Root.Theme.fontSizeTiny
                font.family: Root.Theme.fontFamily
                font.weight: Font.DemiBold
                color: Root.Network.vpnConnected ? Root.Theme.success : Root.Theme.outline
            }

            Root.IconButton {
                icon: "󰅖"
                size: 24
                iconSize: 12
                iconColor: Root.Theme.error
                visible: Root.Network.vpnConnected
                onClicked: Root.Network.protonDisconnect()
            }
        }

        // Country search
        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: Root.Theme.borderRadiusSmall
            color: Root.Theme.surfaceContainerHigh
            border.color: vpnSearchInput.activeFocus ? Root.Theme.primary : "transparent"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "󰍉"
                    font.pixelSize: 12
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.outline
                }

                TextInput {
                    id: vpnSearchInput
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.on.surface
                    clip: true
                    onTextChanged: vpnTab._vpnSearch = text

                    Keys.onEscapePressed: {
                        text = ""
                        focus = false
                    }
                }

                // Placeholder
                Text {
                    text: "Search countries..."
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    color: Root.Theme.outline
                    visible: !vpnSearchInput.text && !vpnSearchInput.activeFocus
                }
            }
        }

        // Loading indicator
        Text {
            text: Root.Network.protonFetching ? "Loading countries..." : ""
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            color: Root.Theme.outline
            visible: Root.Network.protonFetching
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        // Country list (scrollable)
        Flickable {
            id: countryFlickable
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(countryColumn.height, 220)
            contentHeight: countryColumn.height
            clip: true
            visible: !Root.Network.protonFetching && vpnTab._filteredCountries.length > 0
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: Root.StyledScrollBar { target: countryFlickable }

            Column {
                id: countryColumn
                width: parent.width
                spacing: 1

                Repeater {
                    model: vpnTab._filteredCountries

                    Rectangle {
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: 30
                        radius: Root.Theme.borderRadiusSmall
                        color: countryMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"
                        Behavior on color { Root.CAnim {} }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Root.Theme.paddingSmall
                            anchors.rightMargin: Root.Theme.paddingSmall
                            spacing: Root.Theme.spacingSmall

                            Text {
                                text: modelData.name
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamily
                                color: Root.Theme.on.surface
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.code
                                font.pixelSize: Root.Theme.fontSizeTiny
                                font.family: Root.Theme.fontFamily
                                font.weight: Font.DemiBold
                                color: Root.Theme.outline
                            }

                            Text {
                                text: "󰁕"
                                font.pixelSize: 12
                                font.family: Root.Theme.fontFamily
                                color: Root.Theme.primary
                                visible: countryMouse.containsMouse
                            }
                        }

                        MouseArea {
                            id: countryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Root.Network.protonConnecting ? Qt.BusyCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (Root.Network.protonConnecting) return
                                Root.Network.protonConnect(modelData.code)
                            }
                        }
                    }
                }
            }
        }

        // No results
        Text {
            text: vpnTab._vpnSearch ? "No matching countries" : "No countries available"
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            color: Root.Theme.outline
            visible: !Root.Network.protonFetching && vpnTab._filteredCountries.length === 0
                && Root.Network._protonCountriesFetched
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }

    // ─── Divider (between ProtonVPN and NM VPN) ───
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Root.Theme.outlineVariant
        opacity: 0.5
        visible: Root.Network.protonAvailable && Root.Network.vpnConnections.length > 0
    }

    // ─── NM VPN Connections (WireGuard etc.) ───
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Root.Theme.spacingSmall
        visible: Root.Network.vpnConnections.length > 0

        Text {
            text: "VPN Connections"
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            font.weight: Font.Bold
            color: Root.Theme.on.surfaceVariant
        }

        Column {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: Root.Network.vpnConnections

                Rectangle {
                    required property var modelData
                    required property int index

                    width: parent.width
                    height: 36
                    radius: Root.Theme.borderRadiusSmall
                    color: nmVpnMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"
                    Behavior on color { Root.CAnim {} }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Root.Theme.paddingSmall
                        anchors.rightMargin: Root.Theme.paddingSmall
                        spacing: Root.Theme.spacingSmall

                        Text {
                            text: "󰦝"
                            font.pixelSize: 14
                            font.family: Root.Theme.fontFamily
                            color: modelData.active ? Root.Theme.primary : Root.Theme.on.surfaceVariant
                        }

                        TextEdit {
                            text: modelData.name
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            font.weight: modelData.active ? Font.DemiBold : Font.Normal
                            color: modelData.active ? Root.Theme.primary : Root.Theme.on.surface
                            Layout.fillWidth: true
                            readOnly: true
                            selectByMouse: true
                            selectedTextColor: Root.Theme.on.primary
                            selectionColor: Root.Theme.primary
                        }

                        Text {
                            text: modelData.type
                            font.pixelSize: Root.Theme.fontSizeTiny
                            font.family: Root.Theme.fontFamily
                            color: Root.Theme.outline
                        }

                        Text {
                            text: modelData.active ? "Connected"
                                : (Root.Network.vpnConnecting && Root.Network.vpnConnectingName === modelData.name)
                                    ? "Connecting..." : ""
                            font.pixelSize: Root.Theme.fontSizeTiny
                            font.family: Root.Theme.fontFamily
                            color: modelData.active ? Root.Theme.success : Root.Theme.primary
                            visible: modelData.active || (Root.Network.vpnConnecting && Root.Network.vpnConnectingName === modelData.name)
                        }
                    }

                    MouseArea {
                        id: nmVpnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Root.Network.vpnConnecting ? Qt.BusyCursor : Qt.PointingHandCursor
                        onClicked: {
                            if (Root.Network.vpnConnecting) return
                            if (modelData.active)
                                Root.Network.vpnDisconnectByName(modelData.name)
                            else
                                Root.Network.vpnConnectByName(modelData.name)
                        }
                    }
                }
            }
        }
    }

    // Empty state when no VPN options at all
    Text {
        text: Root.Network.protonAvailable ? "" : "No VPN tools configured"
        font.pixelSize: Root.Theme.fontSizeSmall
        font.family: Root.Theme.fontFamily
        color: Root.Theme.outline
        visible: !Root.Network.protonAvailable && Root.Network.vpnConnections.length === 0
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        topPadding: Root.Theme.spacingSmall
        bottomPadding: Root.Theme.spacingSmall
    }
}
