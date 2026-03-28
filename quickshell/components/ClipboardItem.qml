import QtQuick
import QtQuick.Layouts
import ".." as Root

Root.ListItem {
    id: clipItem

    property var entry: modelData
    property bool isMultiline: !entry.isImage && entry.preview.indexOf("\n") !== -1

    signal deleteRequested()

    // Taller for multiline
    height: isMultiline ? Root.Theme.itemHeightLarge : Root.Theme.itemHeightNormal

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Root.Theme.paddingMedium
        anchors.rightMargin: Root.Theme.paddingSmall
        spacing: Root.Theme.spacingMedium

        // Icon for type indication
        Text {
            text: entry.isImage ? "󰋩" : "󰅇"
            font.pixelSize: Root.Theme.iconFontSize
            font.family: Root.Theme.fontFamily
            color: entry.isImage ? Root.Theme.primary : Root.Theme.outline
            Layout.preferredWidth: Root.Theme.iconSizeSmall
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        // Content column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Root.Theme.spacingTiny

            // Preview text (multiline for text, info for images)
            Text {
                text: entry.isImage ? entry.imageInfo : entry.preview.replace(/\n/g, "\u21B5 ")
                font.pixelSize: Root.Theme.fontSizeNormal
                font.family: Root.Theme.fontFamily
                font.weight: Root.Theme.fontWeight
                color: entry.isImage ? Root.Theme.primary : Root.Theme.on.surface
                font.italic: entry.isImage
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
            }

            // Second line for multiline text entries
            Text {
                visible: clipItem.isMultiline
                text: {
                    if (!clipItem.isMultiline) return ""
                    var lines = entry.preview.split("\n")
                    var remaining = lines.slice(1).join(" ").trim()
                    return remaining
                }
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                color: Root.Theme.on.surfaceVariant
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
            }
        }

        // Delete button (visible on hover or selected)
        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            radius: 12
            color: deleteHover.containsMouse ? Root.Theme.surfaceContainerHighest : "transparent"
            visible: clipItem.itemHovered || clipItem.isSelected

            Behavior on color {
                ColorAnimation { duration: Root.Theme.durationFast }
            }

            Text {
                anchors.centerIn: parent
                text: "󰅖"
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                color: deleteHover.containsMouse ? Root.Theme.error : Root.Theme.outline
            }

            MouseArea {
                id: deleteHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: (mouse) => {
                    mouse.accepted = true
                    clipItem.deleteRequested()
                }
            }
        }
    }
}
