import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import ".." as Root

Root.ServicePopup {
    id: audioPopup

    service: Root.Audio
    layerNamespace: "quickshell-audio"
    panelWidth: Root.Theme.popupWidthWide

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Root.Theme.spacingMedium

        // ─── Output Section ───
        Text {
            text: "Output"
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            font.weight: Font.Bold
            color: Root.Theme.on.surfaceVariant
        }

        // Master volume slider
        RowLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall

            Text {
                text: Root.Audio.volumeIcon
                font.pixelSize: Root.Theme.iconFontSize
                font.family: Root.Theme.fontFamily
                color: Root.Audio.muted ? Root.Theme.error : Root.Theme.primary
                Layout.preferredWidth: 24

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Root.Audio.toggleMute()
                }
            }

            Root.ProgressBar {
                Layout.fillWidth: true
                interactive: true
                value: Root.Audio.volumePercent / 100
                fillColor: Root.Audio.muted ? Root.Theme.error : Root.Theme.primary
                onAdjusted: newValue => Root.Audio.setVolume(Math.round(newValue * 100))
            }

            Text {
                text: Root.Audio.volumePercent + "%"
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Root.Theme.fontWeight
                color: Root.Audio.muted ? Root.Theme.error : Root.Theme.on.surface
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
            }
        }

        // Output device list
        Column {
            Layout.fillWidth: true
            spacing: 2
            visible: Root.Audio.sinks.length > 1

            Repeater {
                model: Root.Audio.sinks

                Rectangle {
                    required property var modelData
                    required property int index

                    width: parent.width
                    height: 32
                    radius: Root.Theme.borderRadiusSmall
                    color: sinkMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"
                    Behavior on color { Root.CAnim {} }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Root.Theme.paddingSmall
                        anchors.rightMargin: Root.Theme.paddingSmall
                        spacing: Root.Theme.spacingSmall

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Root.Theme.primary
                            visible: modelData === Pipewire.defaultAudioSink
                        }

                        TextEdit {
                            text: Root.Audio.nodeName(modelData)
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            color: modelData === Pipewire.defaultAudioSink
                                ? Root.Theme.primary : Root.Theme.on.surfaceVariant
                            font.weight: modelData === Pipewire.defaultAudioSink
                                ? Font.DemiBold : Font.Normal
                            Layout.fillWidth: true
                            readOnly: true
                            selectByMouse: true
                            selectedTextColor: Root.Theme.on.primary
                            selectionColor: Root.Theme.primary
                        }
                    }

                    MouseArea {
                        id: sinkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.Audio.setSink(modelData)
                    }
                }
            }
        }

        // ─── Divider ───
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Root.Theme.outlineVariant
            opacity: 0.5
            visible: Root.Audio.sources.length > 0
        }

        // ─── Input Section ───
        Text {
            text: "Input"
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            font.weight: Font.Bold
            color: Root.Theme.on.surfaceVariant
            visible: Root.Audio.sources.length > 0
        }

        // Input volume slider
        RowLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall
            visible: Root.Audio.sources.length > 0

            Text {
                text: Root.Audio.inputIcon
                font.pixelSize: Root.Theme.iconFontSize
                font.family: Root.Theme.fontFamily
                color: Root.Audio.inputMuted ? Root.Theme.error : Root.Theme.secondary
                Layout.preferredWidth: 24

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Root.Audio.toggleInputMute()
                }
            }

            Root.ProgressBar {
                Layout.fillWidth: true
                interactive: true
                value: Root.Audio.inputVolumePercent / 100
                fillColor: Root.Audio.inputMuted ? Root.Theme.error : Root.Theme.secondary
                onAdjusted: newValue => Root.Audio.setInputVolume(Math.round(newValue * 100))
            }

            Text {
                text: Root.Audio.inputVolumePercent + "%"
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Root.Theme.fontWeight
                color: Root.Audio.inputMuted ? Root.Theme.error : Root.Theme.on.surface
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
            }
        }

        // Input device list
        Column {
            Layout.fillWidth: true
            spacing: 2
            visible: Root.Audio.sources.length > 1

            Repeater {
                model: Root.Audio.sources

                Rectangle {
                    required property var modelData
                    required property int index

                    width: parent.width
                    height: 32
                    radius: Root.Theme.borderRadiusSmall
                    color: srcMouse.containsMouse ? Root.Theme.surfaceContainer : "transparent"
                    Behavior on color { Root.CAnim {} }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Root.Theme.paddingSmall
                        anchors.rightMargin: Root.Theme.paddingSmall
                        spacing: Root.Theme.spacingSmall

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Root.Theme.secondary
                            visible: modelData === Pipewire.defaultAudioSource
                        }

                        TextEdit {
                            text: Root.Audio.nodeName(modelData)
                            font.pixelSize: Root.Theme.fontSizeSmall
                            font.family: Root.Theme.fontFamily
                            color: modelData === Pipewire.defaultAudioSource
                                ? Root.Theme.secondary : Root.Theme.on.surfaceVariant
                            font.weight: modelData === Pipewire.defaultAudioSource
                                ? Font.DemiBold : Font.Normal
                            Layout.fillWidth: true
                            readOnly: true
                            selectByMouse: true
                            selectedTextColor: Root.Theme.on.primary
                            selectionColor: Root.Theme.primary
                        }
                    }

                    MouseArea {
                        id: srcMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.Audio.setSource(modelData)
                    }
                }
            }
        }

        // ─── Divider ───
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Root.Theme.outlineVariant
            opacity: 0.5
            visible: streamRepeater.count > 0
        }

        // ─── Per-App Streams ───
        Text {
            text: "Applications"
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            font.weight: Font.Bold
            color: Root.Theme.on.surfaceVariant
            visible: streamRepeater.count > 0
        }

        Column {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingSmall
            visible: streamRepeater.count > 0

            Repeater {
                id: streamRepeater
                model: Root.Audio.streams

                RowLayout {
                    required property var modelData
                    width: parent.width
                    spacing: Root.Theme.spacingSmall

                    Text {
                        text: modelData?.audio?.muted ? "󰝟" : "󰕾"
                        font.pixelSize: 14
                        font.family: Root.Theme.fontFamily
                        color: modelData?.audio?.muted ? Root.Theme.error : Root.Theme.on.surfaceVariant
                        Layout.preferredWidth: 20

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Root.Audio.toggleStreamMute(modelData)
                        }
                    }

                    Text {
                        text: Root.Audio.streamAppName(modelData)
                        font.pixelSize: Root.Theme.fontSizeSmall
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.on.surfaceVariant
                        Layout.preferredWidth: 80
                        elide: Text.ElideRight
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20

                        Rectangle {
                            id: streamTrack
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 3
                            radius: 1.5
                            color: Root.Theme.surfaceContainerHigh

                            Rectangle {
                                property real streamVol: modelData?.audio?.volume ?? 0
                                width: Math.min(1, isNaN(streamVol) ? 0 : streamVol) * parent.width
                                height: parent.height
                                radius: parent.radius
                                color: modelData?.audio?.muted ? Root.Theme.error : Root.Theme.tertiary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: function(mouse) {
                                var pct = Math.max(0, Math.min(100, (mouse.x / streamTrack.width) * 100))
                                Root.Audio.setStreamVolume(modelData, Math.round(pct))
                            }
                            onPositionChanged: function(mouse) {
                                if (pressed) {
                                    var pct = Math.max(0, Math.min(100, (mouse.x / streamTrack.width) * 100))
                                    Root.Audio.setStreamVolume(modelData, Math.round(pct))
                                }
                            }
                        }
                    }

                    Text {
                        property real streamVol: modelData?.audio?.volume ?? 0
                        text: (isNaN(streamVol) ? 0 : Math.round(streamVol * 100)) + "%"
                        font.pixelSize: Root.Theme.fontSizeTiny
                        font.family: Root.Theme.fontFamily
                        color: Root.Theme.on.surfaceVariant
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
