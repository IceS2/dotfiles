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
            visible: Root.Wallpaper.popupVisible && monitorIsFocused
            color: "transparent"

            WlrLayershell.namespace: "quickshell-wallpaper"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: monitorIsFocused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: Region {
                item: Root.Wallpaper.popupVisible ? keyHandler : null
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Entrance animation
            property real animScale: Root.Wallpaper.popupVisible ? 1.0 : 0.96
            property real animOpacity: Root.Wallpaper.popupVisible ? 1.0 : 0.0

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

            Item {
                id: keyHandler
                anchors.fill: parent
                visible: Root.Wallpaper.popupVisible
                focus: Root.Wallpaper.popupVisible
                opacity: panel.animOpacity
                scale: panel.animScale

                // Click-outside-to-close
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: Root.Wallpaper.cancel()
                }

                Keys.onPressed: event => {
                    // Delete confirmation mode — intercept all keys
                    if (Root.Wallpaper.deleteConfirmPending) {
                        if (event.key === Qt.Key_Y) {
                            Root.Wallpaper.confirmDelete();
                        } else {
                            Root.Wallpaper.cancelDelete();
                        }
                        event.accepted = true;
                        return;
                    }

                    if (event.key === Qt.Key_Escape) {
                        Root.Wallpaper.cancel();
                        event.accepted = true;
                        return;
                    }

                    const entries = Root.Wallpaper.entries;
                    const count = entries.length;
                    if (count === 0) return;

                    const idx = Root.Wallpaper.currentIndex;

                    // Navigation
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        Root.Wallpaper.currentIndex = Math.max(0, idx - 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        Root.Wallpaper.currentIndex = Math.min(count - 1, idx + 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Home) {
                        Root.Wallpaper.currentIndex = 0;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_End) {
                        Root.Wallpaper.currentIndex = count - 1;
                        event.accepted = true;
                    }

                    // Cycle mode
                    else if (event.key === Qt.Key_Tab) {
                        Root.Wallpaper.cycleMode();
                        event.accepted = true;
                    }

                    // Delete
                    else if (event.key === Qt.Key_D || event.key === Qt.Key_Delete) {
                        Root.Wallpaper.requestDelete();
                        event.accepted = true;
                    }

                    // Confirm
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        Root.Wallpaper.confirm();
                        event.accepted = true;
                    }
                }

                // Scroll wheel navigation
                MouseArea {
                    anchors.fill: stripContainer
                    z: 1
                    acceptedButtons: Qt.NoButton
                    onWheel: event => {
                        const count = Root.Wallpaper.entries.length;
                        if (count === 0) return;
                        const idx = Root.Wallpaper.currentIndex;
                        if (event.angleDelta.y > 0 || event.angleDelta.x > 0) {
                            Root.Wallpaper.currentIndex = Math.max(0, idx - 1);
                        } else {
                            Root.Wallpaper.currentIndex = Math.min(count - 1, idx + 1);
                        }
                    }
                }

                // Container positioned in lower third of screen
                Item {
                    id: stripContainer
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: parent.height * 0.12
                    }
                    width: Math.min(parent.width - Root.Theme.paddingLarge * 4, 1200)
                    height: contentColumn.implicitHeight

                    // Background panel
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -Root.Theme.paddingLarge
                        radius: Root.Theme.borderRadiusLarge
                        color: Root.Theme.surfaceGlass

                        // Subtle border
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "transparent"
                            border.width: Root.Theme.borderWidthThin
                            border.color: Qt.rgba(Root.Theme.surfaceContainerHigh.r, Root.Theme.surfaceContainerHigh.g, Root.Theme.surfaceContainerHigh.b, 0.3)
                        }
                    }

                    ColumnLayout {
                        id: contentColumn
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: Root.Theme.spacingMedium

                        // Delete confirmation banner
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: deleteConfirmRow.implicitHeight + Root.Theme.spacingSmall * 2
                            radius: Root.Theme.borderRadiusMedium
                            color: Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.15)
                            border.width: Root.Theme.borderWidthThin
                            border.color: Qt.rgba(Root.Theme.error.r, Root.Theme.error.g, Root.Theme.error.b, 0.4)
                            visible: Root.Wallpaper.deleteConfirmPending

                            RowLayout {
                                id: deleteConfirmRow
                                anchors.centerIn: parent
                                spacing: Root.Theme.spacingSmall

                                Text {
                                    text: "󰩹"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeNormal
                                    color: Root.Theme.error
                                }

                                Text {
                                    text: {
                                        const entries = Root.Wallpaper.entries;
                                        const idx = Root.Wallpaper.currentIndex;
                                        if (entries.length === 0) return "Delete?";
                                        return "Trash  " + entries[idx].name + "?";
                                    }
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Root.Theme.error
                                }

                                Text {
                                    text: "  y  confirm  ·  any key  cancel"
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: Root.Theme.fontSizeTiny
                                    color: Root.Theme.on.surfaceVariant
                                }
                            }
                        }

                        // Mode selector pills
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Root.Theme.spacingSmall

                            Repeater {
                                model: Root.Wallpaper.modes

                                Rectangle {
                                    required property string modelData
                                    required property int index
                                    property bool isActive: Root.Wallpaper.mode === modelData

                                    width: modeText.implicitWidth + Root.Theme.spacingLarge
                                    height: modeText.implicitHeight + Root.Theme.spacingSmall
                                    radius: height / 2
                                    color: isActive ? Root.Theme.primary : Root.Theme.surfaceContainer

                                    Behavior on color {
                                        ColorAnimation { duration: Root.Theme.durationFast }
                                    }

                                    Text {
                                        id: modeText
                                        anchors.centerIn: parent
                                        text: Root.Wallpaper.modeLabels[modelData]
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: Root.Theme.fontSizeTiny
                                        font.weight: isActive ? Font.Bold : Font.Medium
                                        color: isActive ? Root.Theme.surfaceContainerLowest : Root.Theme.on.surfaceVariant
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Root.Wallpaper.mode = modelData;
                                            Root.Wallpaper._triggerPreview();
                                        }
                                    }
                                }
                            }
                        }

                        // Thumbnail strip
                        ListView {
                            id: thumbnailList
                            Layout.fillWidth: true
                            Layout.preferredHeight: 160
                            orientation: Qt.Horizontal
                            spacing: Root.Theme.spacingSmall
                            clip: true

                            model: ScriptModel {
                                objectProp: "path"
                                values: Root.Wallpaper.entries
                            }
                            currentIndex: Root.Wallpaper.currentIndex

                            snapMode: ListView.SnapToItem
                            highlightRangeMode: ListView.StrictlyEnforceRange
                            preferredHighlightBegin: (width - 200) / 2
                            preferredHighlightEnd: (width + 200) / 2
                            highlightMoveDuration: Root.Theme.durationNormal

                            delegate: Item {
                                id: thumbDelegate
                                required property var modelData
                                required property int index
                                property bool isSelected: index === thumbnailList.currentIndex
                                property bool isHovered: thumbMouse.containsMouse

                                width: thumbImage.paintedWidth > 0 ? thumbImage.paintedWidth + Root.Theme.spacingSmall : 200
                                height: 160

                                Rectangle {
                                    id: thumbBg
                                    anchors.fill: parent
                                    radius: Root.Theme.borderRadiusMedium
                                    color: "transparent"
                                    clip: true

                                    border.width: thumbDelegate.isSelected ? Root.Theme.borderWidthNormal : (thumbDelegate.isHovered ? Root.Theme.borderWidthThin : 0)
                                    border.color: thumbDelegate.isSelected ? Root.Theme.primary : Root.Theme.surfaceContainerHigh

                                    Behavior on border.width {
                                        NumberAnimation { duration: Root.Theme.durationFast }
                                    }

                                    Image {
                                        id: thumbImage
                                        anchors.centerIn: parent
                                        height: parent.height - Root.Theme.spacingSmall
                                        fillMode: Image.PreserveAspectFit
                                        source: "file://" + modelData.path
                                        sourceSize.height: 160
                                        asynchronous: true
                                        cache: true
                                    }
                                }

                                // Scale animation on selection
                                transform: Scale {
                                    origin.x: thumbDelegate.width / 2
                                    origin.y: thumbDelegate.height / 2
                                    xScale: thumbDelegate.isSelected ? 1.05 : 1.0
                                    yScale: thumbDelegate.isSelected ? 1.05 : 1.0

                                    Behavior on xScale {
                                        NumberAnimation { duration: Root.Theme.durationFast; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on yScale {
                                        NumberAnimation { duration: Root.Theme.durationFast; easing.type: Easing.OutCubic }
                                    }
                                }

                                MouseArea {
                                    id: thumbMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Root.Wallpaper.currentIndex = index;
                                    }
                                    onDoubleClicked: {
                                        Root.Wallpaper.currentIndex = index;
                                        Root.Wallpaper.confirm();
                                    }
                                }
                            }

                            // Empty state
                            Root.EmptyState {
                                anchors.centerIn: parent
                                visible: Root.Wallpaper.entries.length === 0
                                icon: "󰸉"
                                message: "No wallpapers found"
                                subtext: Root.Wallpaper.wallpaperDir
                            }
                        }

                        // Filename display
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                const entries = Root.Wallpaper.entries;
                                const idx = Root.Wallpaper.currentIndex;
                                if (entries.length === 0) return "";
                                return entries[idx].name;
                            }
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Root.Theme.on.surface
                        }

                        // Counter
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            visible: Root.Wallpaper.entries.length > 0
                            text: (Root.Wallpaper.currentIndex + 1) + " / " + Root.Wallpaper.entries.length
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSizeTiny
                            color: Root.Theme.on.surfaceVariant
                        }

                        // Keybind hints
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Root.Theme.spacingLarge

                            Repeater {
                                model: [
                                    { key: "←/→", action: "Navigate" },
                                    { key: "Tab", action: "Mode" },
                                    { key: "d", action: "Delete" },
                                    { key: "Enter", action: "Confirm" },
                                    { key: "Esc", action: "Cancel" }
                                ]

                                Row {
                                    required property var modelData
                                    spacing: Root.Theme.spacingTiny

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: keyLabel.implicitWidth + Root.Theme.spacingSmall
                                        height: keyLabel.implicitHeight + 4
                                        radius: 4
                                        color: Root.Theme.surfaceContainer

                                        Text {
                                            id: keyLabel
                                            anchors.centerIn: parent
                                            text: modelData.key
                                            font.family: Root.Theme.fontFamily
                                            font.pixelSize: Root.Theme.fontSizeTiny
                                            font.weight: Font.Bold
                                            color: Root.Theme.primary
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.action
                                        font.family: Root.Theme.fontFamily
                                        font.pixelSize: Root.Theme.fontSizeTiny
                                        color: Root.Theme.on.surfaceVariant
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
