import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." as Root

Root.PopupPanel {
    id: trayMenuWindow

    showing: Root.Tray.menuVisible
    screen: Root.Tray.activeScreen ?? Quickshell.screens[0]
    layerNamespace: "quickshell-tray-menu"
    growDirection: "down"
    panelX: Math.min(
        Math.max(Root.Tray.menuAnchorX - panelWidth / 2, Root.Theme.gapOuter),
        width - panelWidth - Root.Theme.gapOuter
    )
    panelWidth: Root.Theme.popupWidthMenu
    contentPadding: Root.Theme.paddingSmall

    onCloseRequested: Root.Tray.hideMenu()

    // ─── Menu opener: reads menu entries from the active tray item ───
    QsMenuOpener {
        id: menuOpener
        menu: Root.Tray.menuItem ? Root.Tray.menuItem.menu : null
    }

    // ─── Content ───
    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // ─── Header: app title ───
        Text {
            visible: Root.Tray.menuItem !== null && Root.Tray.menuItem.title !== ""
            text: Root.Tray.menuItem ? Root.Tray.menuItem.title : ""
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            font.weight: Font.Bold
            color: Root.Theme.on.surfaceVariant
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.leftMargin: Root.Theme.paddingSmall
            Layout.topMargin: Root.Theme.spacingTiny
            Layout.bottomMargin: Root.Theme.spacingTiny
        }

        // ─── Header separator ───
        Rectangle {
            visible: Root.Tray.menuItem !== null && Root.Tray.menuItem.title !== ""
            Layout.fillWidth: true
            Layout.leftMargin: Root.Theme.paddingSmall
            Layout.rightMargin: Root.Theme.paddingSmall
            height: 1
            color: Root.Theme.surfaceContainerHigh
            opacity: 0.5
        }

        // ─── Menu entries ───
        Repeater {
            id: menuRepeater
            model: {
                if (!menuOpener.children) return []
                var entries = menuOpener.children.values
                if (!entries) return []

                // Filter: collapse consecutive separators, remove leading/trailing
                var filtered = []
                for (var i = 0; i < entries.length; i++) {
                    var e = entries[i]
                    if (e.isSeparator) {
                        // Skip leading separators
                        if (filtered.length === 0) continue
                        // Skip consecutive separators
                        if (filtered.length > 0 && filtered[filtered.length - 1].isSeparator) continue
                        filtered.push(e)
                    } else {
                        filtered.push(e)
                    }
                }
                // Remove trailing separator
                if (filtered.length > 0 && filtered[filtered.length - 1].isSeparator) {
                    filtered.pop()
                }
                return filtered
            }

            Root.TrayMenuItem {
                required property var modelData
                entry: modelData
                menuWindow: trayMenuWindow
                Layout.fillWidth: true
            }
        }

        // ─── Empty state ───
        Text {
            visible: menuRepeater.count === 0 && Root.Tray.menuVisible
            text: "No menu entries"
            font.pixelSize: Root.Theme.fontSizeSmall
            font.family: Root.Theme.fontFamily
            color: Root.Theme.outline
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.topMargin: Root.Theme.paddingSmall
            Layout.bottomMargin: Root.Theme.paddingSmall
        }
    }
}
