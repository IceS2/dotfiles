import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Root

Root.ServicePopup {
    id: updatesPopup

    service: Root.Updates
    layerNamespace: "quickshell-updates"
    panelWidth: Root.Theme.popupWidthMedium

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.spacingMedium

        // ─── Header ───
        RowLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall

            Text {
                text: "󰏔"
                font.pixelSize: 18
                font.family: Root.Theme.fontFamily
                color: Root.Theme.yellow
            }

            Text {
                text: "System Updates"
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Font.Bold
                color: Root.Theme.on.surface
                Layout.fillWidth: true
            }

            // Last checked time
            Text {
                text: Root.Updates.lastChecked
                font.pixelSize: Root.Theme.fontSizeTiny
                font.family: Root.Theme.fontFamily
                color: Root.Theme.outline
                visible: Root.Updates.lastChecked !== ""
            }

            // Refresh button
            Root.IconButton {
                icon: "󰑐"
                iconColor: Root.Updates.checking ? Root.Theme.primary : Root.Theme.on.surfaceVariant
                size: 24
                iconSize: 14
                onClicked: Root.Updates.refresh()

                RotationAnimation on rotation {
                    running: Root.Updates.checking
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }
        }

        // ─── Critical Section ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall
            visible: Root.Updates.hasCritical

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "⚠"
                    font.pixelSize: 14
                    color: Root.Theme.error
                }

                Text {
                    text: "Critical"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.error
                }
            }

            Repeater {
                model: Root.Updates.criticalPackages

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Root.Theme.spacingSmall

                    TextEdit {
                        text: modelData.name
                        font.pixelSize: Root.Theme.fontSizeTiny
                        font.family: Root.Theme.fontFamilyMono
                        font.weight: Font.DemiBold
                        color: Root.Theme.error
                        readOnly: true
                        selectByMouse: true
                        selectedTextColor: Root.Theme.on.primary
                        selectionColor: Root.Theme.primary
                        Layout.fillWidth: true
                    }

                    TextEdit {
                        text: modelData.oldVer + " → " + modelData.newVer
                        font.pixelSize: Root.Theme.fontSizeTiny
                        font.family: Root.Theme.fontFamilyMono
                        color: Root.Theme.outline
                        readOnly: true
                        selectByMouse: true
                        selectedTextColor: Root.Theme.on.primary
                        selectionColor: Root.Theme.primary
                    }
                }
            }

            // Divider after critical
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Theme.outlineVariant
                opacity: 0.5
            }
        }

        // ─── Official Section ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall
            visible: Root.Updates.officialCount > 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "Official"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surfaceVariant
                    Layout.fillWidth: true
                }

                // Count badge
                Rectangle {
                    width: Math.max(20, officialCountText.implicitWidth + 8)
                    height: 18
                    radius: 9
                    color: Root.Theme.surfaceContainerHigh

                    Text {
                        id: officialCountText
                        anchors.centerIn: parent
                        text: Root.Updates.officialCount
                        font.pixelSize: Root.Theme.fontSizeTiny
                        font.family: Root.Theme.fontFamilyMono
                        font.weight: Font.Bold
                        color: Root.Theme.on.surfaceVariant
                    }
                }
            }

            Flickable {
                id: officialFlickable
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(officialCol.implicitHeight, 200)
                contentHeight: officialCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: Root.StyledScrollBar { target: officialFlickable }

                Column {
                    id: officialCol
                    width: parent.width - 12
                    spacing: 2

                    Repeater {
                        model: Root.Updates.officialPackages

                        Row {
                            width: officialCol.width
                            spacing: Root.Theme.spacingSmall

                            TextEdit {
                                text: modelData.name
                                width: parent.width - versionText.width - parent.spacing
                                font.pixelSize: Root.Theme.fontSizeTiny
                                font.family: Root.Theme.fontFamilyMono
                                color: Root.Theme.on.surface
                                readOnly: true
                                selectByMouse: true
                                selectedTextColor: Root.Theme.on.primary
                                selectionColor: Root.Theme.primary
                                clip: true
                            }

                            TextEdit {
                                id: versionText
                                text: modelData.oldVer + " → " + modelData.newVer
                                font.pixelSize: Root.Theme.fontSizeTiny
                                font.family: Root.Theme.fontFamilyMono
                                color: Root.Theme.outline
                                readOnly: true
                                selectByMouse: true
                                selectedTextColor: Root.Theme.on.primary
                                selectionColor: Root.Theme.primary
                            }
                        }
                    }
                }
            }
        }

        // ─── AUR Section ───
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall
            visible: Root.Updates.aurCount > 0

            // Divider before AUR (when official also visible)
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Theme.outlineVariant
                opacity: 0.5
                visible: Root.Updates.officialCount > 0
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Theme.spacingSmall

                Text {
                    text: "AUR"
                    font.pixelSize: Root.Theme.fontSizeSmall
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.on.surfaceVariant
                    Layout.fillWidth: true
                }

                // Count badge
                Rectangle {
                    width: Math.max(20, aurCountText.implicitWidth + 8)
                    height: 18
                    radius: 9
                    color: Root.Theme.surfaceContainerHigh

                    Text {
                        id: aurCountText
                        anchors.centerIn: parent
                        text: Root.Updates.aurCount
                        font.pixelSize: Root.Theme.fontSizeTiny
                        font.family: Root.Theme.fontFamilyMono
                        font.weight: Font.Bold
                        color: Root.Theme.on.surfaceVariant
                    }
                }
            }

            Flickable {
                id: aurFlickable
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(aurCol.implicitHeight, 200)
                contentHeight: aurCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: Root.StyledScrollBar { target: aurFlickable }

                Column {
                    id: aurCol
                    width: parent.width - 12
                    spacing: 2

                    Repeater {
                        model: Root.Updates.aurPackages

                        Row {
                            width: aurCol.width
                            spacing: Root.Theme.spacingSmall

                            TextEdit {
                                text: modelData.name
                                width: parent.width - aurVerText.width - parent.spacing
                                font.pixelSize: Root.Theme.fontSizeTiny
                                font.family: Root.Theme.fontFamilyMono
                                color: Root.Theme.on.surface
                                readOnly: true
                                selectByMouse: true
                                selectedTextColor: Root.Theme.on.primary
                                selectionColor: Root.Theme.primary
                                clip: true
                            }

                            TextEdit {
                                id: aurVerText
                                text: modelData.oldVer + " → " + modelData.newVer
                                font.pixelSize: Root.Theme.fontSizeTiny
                                font.family: Root.Theme.fontFamilyMono
                                color: Root.Theme.outline
                                readOnly: true
                                selectByMouse: true
                                selectedTextColor: Root.Theme.on.primary
                                selectionColor: Root.Theme.primary
                            }
                        }
                    }
                }
            }
        }

        // ─── Empty State ───
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            visible: !Root.Updates.hasUpdates && !Root.Updates.checking

            Root.EmptyState {
                icon: "󰗠"
                message: "System is up to date"
                subtext: "Last checked: " + Root.Updates.lastChecked
            }
        }

        // ─── Checking State ───
        Text {
            Layout.fillWidth: true
            Layout.topMargin: Root.Theme.spacingMedium
            text: "Checking for updates..."
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            color: Root.Theme.outline
            horizontalAlignment: Text.AlignHCenter
            visible: Root.Updates.checking && !Root.Updates.hasUpdates
        }

        // ─── Footer: Run Update Button ───
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: Root.Theme.spacingSmall
            height: 32
            radius: Root.Theme.borderRadiusSmall
            color: updateBtnMouse.containsMouse
                ? Qt.lighter(Root.Theme.primary, 1.1)
                : Root.Theme.primary
            visible: Root.Updates.hasUpdates

            Behavior on color { Root.CAnim {} }

            Text {
                anchors.centerIn: parent
                text: "󰏔  Run update.sh"
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Font.DemiBold
                color: Root.Theme.on.primary
            }

            MouseArea {
                id: updateBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Root.Updates.launchUpdate()
            }
        }
    }
}
