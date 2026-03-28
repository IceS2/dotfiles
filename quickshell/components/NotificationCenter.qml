import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import ".." as Root

Root.PopupPanel {
    id: centerWindow

    showing: Root.Notifications.centerVisible
    screen: Root.Notifications.activeScreen ?? Quickshell.screens[0]
    layerNamespace: "quickshell-notification-center"
    growDirection: "right"
    panelWidth: Root.Theme.notificationCenterWidth
    panelHeight: height - Root.Theme.barHeight - Root.Theme.gapOuter * 2
    contentPadding: Root.Theme.paddingLarge

    onCloseRequested: Root.Notifications.hideCenter()

    // ─── Mutual exclusion: close calendar when notification center opens ───
    Connections {
        target: Root.Notifications
        function onCenterVisibleChanged() {
            if (Root.Notifications.centerVisible)
                Root.Calendar.hidePopup()
        }
    }

    // ─── Notification-specific keyboard shortcuts ───
    Shortcut {
        sequence: "Ctrl+L"
        onActivated: Root.Notifications.clearAll()
    }

    Shortcut {
        sequence: "D"
        onActivated: Root.Notifications.toggleDnd()
    }

    Shortcut {
        sequence: "S"
        onActivated: {
            Root.Notifications.soundEnabled = !Root.Notifications.soundEnabled
            Root.Notifications.saveTimer.restart()
        }
    }

    // ─── Content ───
    ColumnLayout {
        anchors.fill: parent
        spacing: Root.Theme.spacingSmall

        // ─── System Overview ───
        Root.SystemOverview {
            Layout.fillWidth: true
        }

        // ─── Divider ───
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Root.Theme.outlineVariant
            opacity: 0.5
        }

        // ─── Header ───
        RowLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall

            Text {
                text: "Notifications"
                font.pixelSize: Root.Theme.fontSizeLarge
                font.family: Root.Theme.fontFamily
                font.weight: Font.Bold
                color: Root.Theme.on.surface
            }

            // Count badge
            Rectangle {
                width: badgeText.implicitWidth + 12
                height: 20
                radius: 10
                color: Root.Theme.primary
                visible: Root.Notifications.count > 0

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: Root.Notifications.count
                    font.pixelSize: Root.Theme.fontSizeCaption
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.surface
                }
            }

            Item { Layout.fillWidth: true }

            // Sound toggle (click=on/off, scroll=volume)
            Rectangle {
                width: soundRow.implicitWidth + Root.Theme.paddingSmall * 2
                height: 30
                radius: Root.Theme.borderRadiusSmall
                color: soundHover.containsMouse ? Root.Theme.surfaceContainer : "transparent"

                Behavior on color { Root.CAnim {} }

                Row {
                    id: soundRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: Root.Notifications.soundEnabled ? "󰕾" : "󰖁"
                        font.pixelSize: Root.Theme.fontSizeNormal
                        font.family: Root.Theme.fontFamily
                        color: Root.Notifications.soundEnabled ? Root.Theme.on.surface : Root.Theme.outline
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: Math.round(Root.Notifications.soundVolume * 100) + "%"
                        font.pixelSize: Root.Theme.fontSizeCaption
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.outline
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Root.Notifications.soundEnabled
                    }
                }

                MouseArea {
                    id: soundHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Root.Notifications.soundEnabled = !Root.Notifications.soundEnabled
                        Root.Notifications.saveTimer.restart()
                    }
                    onWheel: wheel => {
                        const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                        Root.Notifications.soundVolume = Math.max(0, Math.min(1, Root.Notifications.soundVolume + delta))
                        Root.Notifications.saveTimer.restart()
                    }
                }
            }

            // DND toggle
            Root.IconButton {
                size: 30
                iconSize: Root.Theme.fontSizeNormal
                icon: Root.Notifications.dnd ? "󰂛" : "󰂚"
                iconColor: Root.Notifications.dnd ? Root.Theme.error : Root.Theme.on.surface
                color: Root.Notifications.dnd
                    ? Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.3)
                    : (hovered ? Root.Theme.surfaceContainer : "transparent")
                border.color: Root.Notifications.dnd ? Root.Theme.error : "transparent"
                border.width: Root.Notifications.dnd ? 1 : 0
                onClicked: Root.Notifications.toggleDnd()
            }

            // Clear all button
            Rectangle {
                width: clearRow.implicitWidth + Root.Theme.paddingSmall * 2
                height: 30
                radius: Root.Theme.borderRadiusSmall
                color: clearHover.containsMouse ? Root.Theme.error : Root.Theme.surfaceContainer
                visible: Root.Notifications.count > 0

                Behavior on color { Root.CAnim {} }

                Row {
                    id: clearRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "Clear"
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.family: Root.Theme.fontFamily
                        font.weight: Root.Theme.fontWeight
                        color: Root.Theme.on.surface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Root.Notifications.clearAll()
                }
            }
        }

        // ─── Separator ───
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: Root.Theme.spacingSmall
            height: 1
            color: Root.Theme.surfaceContainer
            opacity: 0.5
        }

        // ─── Grouped Notification List or Empty State ───
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Root.Theme.spacingSmall

            Flickable {
                id: flickable
                anchors.fill: parent
                contentHeight: groupColumn.implicitHeight
                clip: true
                visible: Root.Notifications.count > 0
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: Root.StyledScrollBar {
                    target: flickable
                }

                Column {
                    id: groupColumn
                    width: parent.width - 12  // Leave room for scrollbar
                    spacing: Root.Theme.spacingMedium

                    Repeater {
                        model: Root.Notifications.grouped

                        Column {
                            required property var modelData
                            width: groupColumn.width
                            spacing: Root.Theme.spacingSmall

                            property bool collapsed: Root.Notifications.isGroupCollapsed(modelData.appName)

                            // ─── Group Header ───
                            Rectangle {
                                width: parent.width
                                height: 28
                                radius: Root.Theme.borderRadiusSmall
                                color: groupHeaderMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"

                                Behavior on color { Root.CAnim {} }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: Root.Theme.paddingSmall
                                    anchors.rightMargin: Root.Theme.paddingSmall
                                    spacing: Root.Theme.spacingSmall

                                    // Collapse chevron
                                    Text {
                                        text: collapsed ? "󰅂" : "󰅀"
                                        font.pixelSize: 12
                                        font.family: Root.Theme.fontFamily
                                        color: Root.Theme.outline
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // App icon
                                    Root.Icon {
                                        icon: modelData.appIcon
                                        size: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: modelData.appIcon !== ""
                                    }

                                    // App name
                                    Text {
                                        text: modelData.appName
                                        font.pixelSize: Root.Theme.fontSizeSmall
                                        font.family: Root.Theme.fontFamily
                                        font.weight: Font.Bold
                                        color: Root.Theme.on.surfaceVariant
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // Count
                                    Text {
                                        text: "(" + modelData.items.length + ")"
                                        font.pixelSize: Root.Theme.fontSizeCaption
                                        font.family: Root.Theme.fontFamily
                                        color: Root.Theme.outline
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Per-app controls (right side)
                                Row {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Root.Theme.paddingSmall
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    // Mute popup toggle
                                    Rectangle {
                                        property bool muted: Root.Notifications.getRule(modelData.appName).mutePopup
                                        width: 20
                                        height: 20
                                        radius: Root.Theme.borderRadiusSmall
                                        color: muteAppMouse.containsMouse ? Root.Theme.surfaceContainerHigh : "transparent"
                                        opacity: muteAppMouse.containsMouse || muted ? 1.0 : 0.4

                                        Behavior on color { Root.CAnim {} }
                                        Behavior on opacity {
                                            NumberAnimation { duration: Root.Theme.durationFast }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: parent.muted ? "󰂛" : "󰂚"
                                            font.pixelSize: 12
                                            font.family: Root.Theme.fontFamily
                                            color: parent.muted ? Root.Theme.error : Root.Theme.outline
                                        }

                                        MouseArea {
                                            id: muteAppMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Root.Notifications.toggleAppMutePopup(modelData.appName)
                                        }
                                    }

                                    // Clear app button
                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: Root.Theme.borderRadiusSmall
                                        color: clearAppMouse.containsMouse ? Root.Theme.error : "transparent"
                                        opacity: clearAppMouse.containsMouse ? 1.0 : 0.5

                                        Behavior on color { Root.CAnim {} }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "×"
                                            font.pixelSize: 12
                                            font.family: Root.Theme.fontFamily
                                            font.weight: Font.Bold
                                            color: Root.Theme.on.surface
                                        }

                                        MouseArea {
                                            id: clearAppMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Root.Notifications.clearApp(modelData.appName)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: groupHeaderMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    // Let clear button clicks through
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: Root.Notifications.toggleGroup(modelData.appName)
                                    z: -1
                                }
                            }

                            // ─── Group Cards ───
                            Column {
                                width: parent.width
                                spacing: Root.Theme.spacingSmall
                                visible: !collapsed

                                Repeater {
                                    model: modelData.items

                                    Root.NotificationCard {
                                        required property var modelData
                                        width: parent.width
                                        notif: modelData
                                        showActions: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Root.EmptyState {
                visible: Root.Notifications.count === 0
                icon: "󰂚"
                message: "No notifications"
                subtext: "You're all caught up"
            }
        }
    }
}
