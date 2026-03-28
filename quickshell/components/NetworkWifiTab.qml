import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Root

ColumnLayout {
    id: wifiTab
    spacing: Root.Theme.spacingMedium

    // ─── Internal State ───
    property string _connectSsid: ""
    property bool _showPassword: false
    property bool _passwordRevealed: false

    // Reset state when popup closes
    Connections {
        target: Root.Network
        function onPopupVisibleChanged() {
            if (!Root.Network.popupVisible) {
                wifiTab._connectSsid = ""
                wifiTab._showPassword = false
                wifiTab._passwordRevealed = false
            }
        }
    }

    // WiFi Connection Feedback
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: feedbackRow.implicitHeight + Root.Theme.paddingSmall * 2
        radius: Root.Theme.borderRadiusSmall
        visible: Root.Network.connecting || Root.Network.connectError !== "" || Root.Network.connectSuccess
        color: Root.Network.connectError !== ""
            ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.15)
            : Root.Network.connectSuccess
                ? Qt.rgba(Root.Theme.success.r, Root.Theme.success.g, Root.Theme.success.b, 0.15)
                : Qt.rgba(Root.Theme.primary.r, Root.Theme.primary.g, Root.Theme.primary.b, 0.15)

        RowLayout {
            id: feedbackRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Root.Theme.paddingSmall
            anchors.leftMargin: Root.Theme.paddingSmall
            anchors.rightMargin: Root.Theme.paddingSmall
            spacing: Root.Theme.spacingSmall

            Text {
                text: Root.Network.connecting ? "󰔟"
                    : Root.Network.connectError !== "" ? "󰅖" : "󰄬"
                font.pixelSize: 14
                font.family: Root.Theme.fontFamily
                color: Root.Network.connectError !== "" ? Root.Theme.error
                    : Root.Network.connectSuccess ? Root.Theme.success : Root.Theme.primary
            }

            Text {
                text: {
                    if (Root.Network.connecting)
                        return "Connecting to " + Root.Network.connectingSsid + "..."
                    if (Root.Network.connectError !== "")
                        return Root.Network.connectError
                    if (Root.Network.connectSuccess)
                        return "Connected successfully"
                    return ""
                }
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                color: Root.Network.connectError !== "" ? Root.Theme.error
                    : Root.Network.connectSuccess ? Root.Theme.success : Root.Theme.on.surface
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                maximumLineCount: 3
            }
        }
    }

    // WiFi Networks Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Root.Theme.spacingSmall

        Text {
            text: "WiFi"
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            font.weight: Font.Bold
            color: Root.Theme.on.surfaceVariant
            Layout.fillWidth: true
        }

        Text {
            text: Root.Network.scanning ? "Scanning..." : ""
            font.pixelSize: Root.Theme.fontSizeTiny
            font.family: Root.Theme.fontFamily
            color: Root.Theme.outline
        }

        Root.IconButton {
            icon: "󰑐"
            size: 24
            iconSize: 14
            iconColor: Root.Network.scanning ? Root.Theme.primary : Root.Theme.on.surfaceVariant
            visible: Root.Network.wifiEnabled
            onClicked: Root.Network.scanWifi()
        }

        // WiFi on/off toggle
        Rectangle {
            width: 36
            height: 20
            radius: 10
            color: Root.Network.wifiEnabled ? Root.Theme.primary : Root.Theme.surfaceContainerHigh
            Behavior on color { Root.CAnim {} }

            Rectangle {
                width: 16
                height: 16
                radius: 8
                x: Root.Network.wifiEnabled ? parent.width - width - 2 : 2
                anchors.verticalCenter: parent.verticalCenter
                color: Root.Network.wifiEnabled ? Root.Theme.on.primary : Root.Theme.outline

                Behavior on x { NumberAnimation { duration: Root.Theme.durationNormal; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Root.Network.toggleWifi()
            }
        }
    }

    // WiFi disabled message
    Text {
        text: "WiFi is turned off"
        font.pixelSize: Root.Theme.fontSizeSmall
        font.family: Root.Theme.fontFamily
        color: Root.Theme.outline
        visible: !Root.Network.wifiEnabled
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        topPadding: Root.Theme.spacingSmall
        bottomPadding: Root.Theme.spacingSmall
    }

    // WiFi Network List
    Flickable {
        id: wifiFlickable
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(wifiColumn.height, 250)
        contentHeight: wifiColumn.height
        clip: true
        visible: Root.Network.wifiEnabled && Root.Network.wifiNetworks.length > 0
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: Root.StyledScrollBar { target: wifiFlickable }

        Column {
            id: wifiColumn
            width: parent.width
            spacing: 2

        Repeater {
            model: Root.Network.wifiNetworks

            Rectangle {
                id: wifiDelegate
                required property var modelData
                required property int index

                property var _ssid: modelData.ssid
                // Explicit dep on savedWifiConnections so QML tracks the array change
                property var _savedList: Root.Network.savedWifiConnections
                property bool _isKnown: { _savedList; return Root.Network.isKnownNetwork(_ssid) }
                property var _saved: { _savedList; return Root.Network.getSavedConnection(_ssid) }
                property bool _showingPassword: wifiTab._connectSsid === _ssid && wifiTab._showPassword

                width: parent.width
                height: _showingPassword ? 64 : 36
                radius: Root.Theme.borderRadiusSmall
                color: netMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"
                clip: true
                Behavior on color { Root.CAnim {} }
                Behavior on height { NumberAnimation { duration: Root.Theme.durationNormal; easing.type: Easing.OutCubic } }

                // Row-level hover + click (behind buttons via z-order)
                MouseArea {
                    id: netMouse
                    anchors.fill: parent
                    anchors.bottomMargin: _showingPassword ? 28 : 0
                    hoverEnabled: true
                    cursorShape: Root.Network.connecting ? Qt.BusyCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.inUse || Root.Network.connecting) return
                        if (modelData.secured && !wifiDelegate._isKnown) {
                            wifiTab._connectSsid = wifiDelegate._ssid
                            wifiTab._showPassword = true
                        } else {
                            Root.Network.connectWifi(wifiDelegate._ssid, "")
                        }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Root.Theme.paddingSmall
                    anchors.rightMargin: Root.Theme.paddingSmall
                    spacing: Root.Theme.spacingTiny

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        spacing: Root.Theme.spacingSmall

                        Text {
                            text: Root.Network.signalIcon(modelData.signal)
                            font.pixelSize: 14
                            font.family: Root.Theme.fontFamily
                            color: modelData.inUse ? Root.Theme.primary
                                : (Root.Network.connecting && Root.Network.connectingSsid === wifiDelegate._ssid)
                                    ? Root.Theme.outline : Root.Theme.on.surfaceVariant
                        }

                        Text {
                            text: wifiDelegate._ssid
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            color: modelData.inUse ? Root.Theme.primary : Root.Theme.on.surface
                            font.weight: modelData.inUse ? Font.DemiBold : Font.Normal
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "󰌾"
                            font.pixelSize: 10
                            font.family: Root.Theme.fontFamily
                            color: Root.Theme.outline
                            visible: modelData.secured
                        }

                        Text {
                            text: modelData.inUse ? "Connected"
                                : (Root.Network.connecting && Root.Network.connectingSsid === wifiDelegate._ssid)
                                    ? "Connecting..." : modelData.signal + "%"
                            font.pixelSize: Root.Theme.fontSizeTiny
                            font.family: Root.Theme.fontFamily
                            color: modelData.inUse ? Root.Theme.success
                                : (Root.Network.connecting && Root.Network.connectingSsid === wifiDelegate._ssid)
                                    ? Root.Theme.primary : Root.Theme.outline
                        }

                        // Auto-connect button (saved networks only)
                        Item {
                            width: 22
                            height: 22
                            visible: _isKnown

                            Rectangle {
                                anchors.fill: parent
                                radius: Root.Theme.borderRadiusSmall
                                color: autoMouse.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                                Behavior on color { Root.CAnim {} }

                                Text {
                                    anchors.centerIn: parent
                                    text: _saved && _saved.autoconnect ? "󰄬" : "󰄱"
                                    font.pixelSize: 12
                                    font.family: Root.Theme.fontFamily
                                    color: _saved && _saved.autoconnect ? Root.Theme.primary : Root.Theme.outline
                                }
                            }

                            MouseArea {
                                id: autoMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var nets = Root.Network.wifiNetworks
                                    if (wifiDelegate.index < nets.length) {
                                        var ssid = nets[wifiDelegate.index].ssid
                                        var saved = Root.Network.getSavedConnection(ssid)
                                        if (saved) Root.Network.setWifiAutoConnect(ssid, !saved.autoconnect)
                                    }
                                }
                                onContainsMouseChanged: {
                                    if (containsMouse) autoTipTimer.start()
                                    else { autoTipTimer.stop(); autoTip.visible = false }
                                }
                            }

                            Timer {
                                id: autoTipTimer
                                interval: 5000
                                onTriggered: autoTip.visible = true
                            }

                            Rectangle {
                                id: autoTip
                                visible: false
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 4
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: autoTipText.width + 8
                                height: autoTipText.height + 4
                                radius: 4
                                color: Root.Theme.surfaceContainerHigh

                                Text {
                                    id: autoTipText
                                    anchors.centerIn: parent
                                    text: _saved && _saved.autoconnect ? "Auto-connect on" : "Auto-connect off"
                                    font.pixelSize: Root.Theme.fontSizeTiny
                                    font.family: Root.Theme.fontFamily
                                    color: Root.Theme.on.surface
                                }
                            }
                        }

                        // Forget button (saved networks only)
                        Item {
                            width: 22
                            height: 22
                            visible: _isKnown

                            Rectangle {
                                anchors.fill: parent
                                radius: Root.Theme.borderRadiusSmall
                                color: forgetMouse.containsMouse ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.15)
                                    : "transparent"
                                Behavior on color { Root.CAnim {} }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    font.pixelSize: 12
                                    font.family: Root.Theme.fontFamily
                                    color: Root.Theme.error
                                }
                            }

                            MouseArea {
                                id: forgetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var nets = Root.Network.wifiNetworks
                                    if (wifiDelegate.index < nets.length)
                                        Root.Network.forgetWifiConnection(nets[wifiDelegate.index].ssid)
                                }
                                onContainsMouseChanged: {
                                    if (containsMouse) forgetTipTimer.start()
                                    else { forgetTipTimer.stop(); forgetTip.visible = false }
                                }
                            }

                            Timer {
                                id: forgetTipTimer
                                interval: 5000
                                onTriggered: forgetTip.visible = true
                            }

                            Rectangle {
                                id: forgetTip
                                visible: false
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 4
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: forgetTipText.width + 8
                                height: forgetTipText.height + 4
                                radius: 4
                                color: Root.Theme.surfaceContainerHigh

                                Text {
                                    id: forgetTipText
                                    anchors.centerIn: parent
                                    text: "Forget network"
                                    font.pixelSize: Root.Theme.fontSizeTiny
                                    font.family: Root.Theme.fontFamily
                                    color: Root.Theme.on.surface
                                }
                            }
                        }
                    }

                    // Password input row (only for unknown secured networks)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        visible: _showingPassword
                        spacing: Root.Theme.spacingSmall

                        Rectangle {
                            Layout.fillWidth: true
                            height: 24
                            radius: Root.Theme.borderRadiusSmall
                            color: Root.Theme.surfaceContainerHigh
                            border.color: pwdInput.activeFocus ? Root.Theme.primary : "transparent"
                            border.width: 1

                            TextInput {
                                id: pwdInput
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: Root.Theme.fontSizeSmall
                                font.family: Root.Theme.fontFamily
                                color: Root.Theme.on.surface
                                echoMode: wifiTab._passwordRevealed ? TextInput.Normal : TextInput.Password
                                clip: true
                                Component.onCompleted: if (visible) forceActiveFocus()

                                Keys.onReturnPressed: {
                                    Root.Network.connectWifi(wifiDelegate._ssid, text)
                                    wifiTab._showPassword = false
                                    wifiTab._connectSsid = ""
                                    wifiTab._passwordRevealed = false
                                }
                                Keys.onEscapePressed: {
                                    wifiTab._showPassword = false
                                    wifiTab._connectSsid = ""
                                    wifiTab._passwordRevealed = false
                                }
                            }
                        }

                        Root.IconButton {
                            icon: wifiTab._passwordRevealed ? "󰈉" : "󰈈"
                            size: 24
                            iconSize: 14
                            iconColor: Root.Theme.on.surfaceVariant
                            onClicked: wifiTab._passwordRevealed = !wifiTab._passwordRevealed
                        }

                        Root.IconButton {
                            icon: "󰁕"
                            size: 24
                            iconSize: 14
                            iconColor: Root.Theme.primary
                            onClicked: {
                                Root.Network.connectWifi(wifiDelegate._ssid, pwdInput.text)
                                wifiTab._showPassword = false
                                wifiTab._connectSsid = ""
                                wifiTab._passwordRevealed = false
                            }
                        }
                    }
                }
            }
        }
        }
    }

    Text {
        text: Root.Network.scanning ? "Scanning for networks..." : "No WiFi networks found"
        font.pixelSize: Root.Theme.fontSizeSmall
        font.family: Root.Theme.fontFamily
        color: Root.Theme.outline
        visible: Root.Network.wifiEnabled && Root.Network.wifiNetworks.length === 0
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        topPadding: Root.Theme.spacingSmall
        bottomPadding: Root.Theme.spacingSmall
    }
}
