import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".." as Root

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panel.screen)
            property bool monitorIsFocused: Hyprland.focusedMonitor?.id === monitor?.id

            screen: modelData
            visible: Root.PowerMenu.popupVisible
            color: "transparent"

            WlrLayershell.namespace: "quickshell-power"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: monitorIsFocused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: Region {
                item: Root.PowerMenu.popupVisible ? keyHandler : null
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                id: keyHandler
                anchors.fill: parent
                visible: Root.PowerMenu.popupVisible
                focus: Root.PowerMenu.popupVisible

                // Click-outside-to-close (behind content)
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: Root.PowerMenu.hidePopup()
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        Root.PowerMenu.hidePopup()
                        event.accepted = true
                    } else if (event.key === Qt.Key_L) {
                        Root.PowerMenu.lockScreen()
                        event.accepted = true
                    } else if (event.key === Qt.Key_S) {
                        Root.PowerMenu.suspend()
                        event.accepted = true
                    } else if (event.key === Qt.Key_R) {
                        Root.PowerMenu.reboot()
                        event.accepted = true
                    } else if (event.key === Qt.Key_P) {
                        Root.PowerMenu.shutdown()
                        event.accepted = true
                    }
                }

                // ─── Scrim (dark overlay) ───
                Rectangle {
                    anchors.fill: parent
                    color: Root.Theme.scrim
                    opacity: Root.PowerMenu.popupVisible ? 0.6 : 0.0

                    Behavior on opacity {
                        OpacityAnimator {
                            duration: Root.Theme.durationNormal
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                // ─── Centered Content ───
                Item {
                    id: contentContainer
                    anchors.centerIn: parent

                    property real animScale: Root.PowerMenu.popupVisible ? 1.0 : 0.92
                    property real animOpacity: Root.PowerMenu.popupVisible ? 1.0 : 0.0

                    transform: Scale {
                        origin.x: contentContainer.width / 2
                        origin.y: contentContainer.height / 2
                        xScale: contentContainer.animScale
                        yScale: contentContainer.animScale
                    }
                    opacity: contentContainer.animOpacity

                    Behavior on animScale {
                        NumberAnimation {
                            duration: Root.Theme.durationNormal
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on animOpacity {
                        NumberAnimation {
                            duration: Root.Theme.durationNormal
                            easing.type: Easing.OutCubic
                        }
                    }

                    width: grid.implicitWidth
                    height: grid.implicitHeight + hintText.implicitHeight + Root.Theme.spacingLarge

                    // ─── 2x2 Button Grid ───
                    GridLayout {
                        id: grid
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        columns: 2
                        rowSpacing: Root.Theme.spacingLarge
                        columnSpacing: Root.Theme.spacingLarge

                        PowerButton {
                            icon: "󰌾"
                            label: "Lock"
                            hint: "L"
                            accentColor: Root.Theme.primary
                            onClicked: Root.PowerMenu.lockScreen()
                        }

                        PowerButton {
                            icon: "󰤄"
                            label: "Suspend"
                            hint: "S"
                            accentColor: Root.Theme.secondary
                            onClicked: Root.PowerMenu.suspend()
                        }

                        PowerButton {
                            icon: "󰜉"
                            label: "Reboot"
                            hint: "R"
                            accentColor: Root.Theme.caution
                            confirmRequired: true
                            onClicked: Root.PowerMenu.reboot()
                        }

                        PowerButton {
                            icon: "󰐥"
                            label: "Shutdown"
                            hint: "P"
                            accentColor: Root.Theme.error
                            confirmRequired: true
                            onClicked: Root.PowerMenu.shutdown()
                        }
                    }

                    // ─── Hint Text ───
                    Text {
                        id: hintText
                        anchors.top: grid.bottom
                        anchors.topMargin: Root.Theme.spacingLarge
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Press Escape to cancel"
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.outline
                        opacity: 0.7
                    }
                }
            }
        }
    }

    // ─── Power Button ───
    component PowerButton: Rectangle {
        id: btn

        property string icon: ""
        property string label: ""
        property string hint: ""
        property color accentColor: Root.Theme.primary
        property bool confirmRequired: false

        // Internal confirm state
        property bool _confirming: false

        signal clicked()

        width: 280
        height: 280
        radius: Root.Theme.borderRadiusMedium
        color: Root.Theme.pillBackground
        border.width: btnMouse.containsMouse || _confirming ? 2 : 1
        border.color: btnMouse.containsMouse || _confirming
            ? Qt.rgba(btn.accentColor.r, btn.accentColor.g, btn.accentColor.b, 0.6)
            : Root.Theme.pillBorder

        Behavior on color { Root.CAnim {} }
        Behavior on border.color { Root.CAnim {} }
        Behavior on border.width {
            NumberAnimation { duration: Root.Theme.durationFast; easing.type: Easing.OutCubic }
        }

        // Hover tint
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: btn.accentColor
            opacity: btnMouse.containsMouse ? 0.06 : 0.0

            Behavior on opacity {
                OpacityAnimator { duration: Root.Theme.durationFast; easing.type: Easing.OutCubic }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Root.Theme.spacingSmall

            // Icon
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: btn.icon
                font.pixelSize: 72
                font.family: Root.Theme.fontFamily
                color: btn._confirming ? btn.accentColor : Root.Theme.on.surface
            }

            // Label or "Confirm?" text
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: btn._confirming ? "Confirm?" : btn.label
                font.pixelSize: Root.Theme.fontSizeLarge
                font.family: Root.Theme.fontFamily
                font.weight: Font.Medium
                color: btn._confirming ? btn.accentColor : Root.Theme.on.surface
            }

            // Keyboard hint
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 32
                height: 26
                radius: 4
                color: Root.Theme.surfaceContainerHigh
                visible: !btn._confirming

                Text {
                    anchors.centerIn: parent
                    text: btn.hint
                    font.pixelSize: Root.Theme.fontSizeCaption
                    font.family: Root.Theme.fontFamily
                    font.weight: Font.Bold
                    color: Root.Theme.outline
                }
            }
        }

        // Confirm timeout — resets after 3s
        Timer {
            id: confirmTimer
            interval: 3000
            onTriggered: btn._confirming = false
        }

        // Reset confirm state when popup closes
        Connections {
            target: Root.PowerMenu
            function onPopupVisibleChanged() {
                if (!Root.PowerMenu.popupVisible) {
                    btn._confirming = false
                    confirmTimer.stop()
                }
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (btn.confirmRequired && !btn._confirming) {
                    btn._confirming = true
                    confirmTimer.restart()
                } else {
                    btn.clicked()
                }
            }
        }
    }
}
