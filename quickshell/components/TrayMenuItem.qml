import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".." as Root

Item {
    id: menuItem

    required property var entry
    // Parent TrayMenu window reference for entry.display() calls
    required property var menuWindow

    width: parent ? parent.width : 200
    height: entry.isSeparator ? separatorRect.height + 8 : 32

    // ─── Separator ───
    Rectangle {
        id: separatorRect
        visible: entry.isSeparator
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Root.Theme.paddingSmall
        anchors.rightMargin: Root.Theme.paddingSmall
        height: 1
        color: Root.Theme.surfaceContainerHigh
        opacity: 0.5
    }

    // ─── Normal entry ───
    Rectangle {
        id: entryBg
        visible: !entry.isSeparator
        anchors.fill: parent
        radius: Root.Theme.borderRadiusSmall
        color: entryMouse.containsMouse && entry.enabled ? Root.Theme.surfaceContainer : "transparent"

        Behavior on color { Root.CAnim {} }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Root.Theme.paddingSmall
            anchors.rightMargin: Root.Theme.paddingSmall
            spacing: Root.Theme.spacingSmall

            // ─── Checkbox / Radio indicator ───
            Text {
                visible: entry.buttonType !== QsMenuButtonType.None
                text: {
                    if (entry.buttonType === QsMenuButtonType.CheckBox)
                        return entry.checkState === Qt.Checked ? "󰄵" : "󰄱"
                    if (entry.buttonType === QsMenuButtonType.RadioButton)
                        return entry.checkState === Qt.Checked ? "󰄴" : "󰄱"
                    return ""
                }
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                color: entry.checkState === Qt.Checked ? Root.Theme.primary : Root.Theme.outline
                Layout.preferredWidth: Root.Theme.fontSizeSmall
            }

            // ─── Icon ───
            IconImage {
                visible: entry.icon !== ""
                source: entry.icon
                implicitSize: 16
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }

            // ─── Label ───
            Text {
                text: entry.text
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                font.weight: Root.Theme.fontWeight
                color: entry.enabled ? Root.Theme.on.surface : Root.Theme.outline
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // ─── Submenu arrow ───
            Text {
                visible: entry.hasChildren
                text: "󰅂"
                font.pixelSize: Root.Theme.fontSizeSmall
                font.family: Root.Theme.fontFamily
                color: Root.Theme.on.surfaceVariant
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: entryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: entry.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: {
                if (!entry.enabled) return

                if (entry.hasChildren) {
                    // Open native submenu at click position
                    entry.display(menuWindow, entryMouse.mouseX, menuItem.mapToItem(null, 0, 0).y + menuItem.height / 2)
                } else {
                    entry.triggered()
                    // Keep menu open for checkbox/radio toggles, close for regular actions
                    if (entry.buttonType === QsMenuButtonType.None) {
                        Root.Tray.hideMenu()
                    }
                }
            }
        }
    }
}
