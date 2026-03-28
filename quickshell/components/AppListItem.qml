import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import ".." as Root

Root.ListItem {
    id: root

    property var app: modelData || null

    RowLayout {
        anchors.fill: parent
        anchors.margins: Root.Theme.paddingSmall
        spacing: Root.Theme.spacingMedium

        // App icon
        Root.Icon {
            Layout.preferredWidth: Root.Theme.iconSizeNormal
            Layout.preferredHeight: Root.Theme.iconSizeNormal
            icon: app?.icon ?? ""
            size: Root.Theme.iconSizeNormal
        }

        // App info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Root.Theme.spacingTiny

            Text {
                text: app?.name ?? "Unknown"
                font.pixelSize: Root.Theme.fontSizeNormal
                font.family: Root.Theme.fontFamily
                font.weight: Root.Theme.fontWeight
                color: Root.Theme.on.surface
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: app?.description ?? ""
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Root.Theme.fontWeight
                color: Root.Theme.on.surfaceVariant
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }
        }
    }
}
