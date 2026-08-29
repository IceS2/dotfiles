import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import ".." as Root
import "../services/utils.js" as Utils

Root.BarWidget {
    id: trayInline
    acceptedButtons: Qt.NoButton
    tintColor: Root.Theme.on.surface

    // Exposed for parent pill visibility binding
    readonly property bool hasItems: _activeItems.length > 0

    // Filter non-Passive items
    readonly property var _activeItems: {
        var items = SystemTray.items.values
        if (!items) return []
        var result = []
        for (var i = 0; i < items.length; i++) {
            if (items[i].status !== Status.Passive)
                result.push(items[i])
        }
        return result
    }

    readonly property int _maxInline: 3
    readonly property bool _hasOverflow: _activeItems.length > _maxInline

    Row {
        spacing: Root.Theme.spacingSmall

        // Inline tray icons (up to 3)
        Repeater {
            model: trayInline._activeItems.slice(0, trayInline._maxInline)

            Item {
                id: inlineItem
                required property var modelData

                width: 18
                height: 18

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 18
                    source: inlineItem.modelData.icon
                }

                // NeedsAttention dot
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -1
                    anchors.rightMargin: -1
                    width: 6
                    height: 6
                    radius: 3
                    color: Root.Theme.error
                    visible: inlineItem.modelData.status === Status.NeedsAttention
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        var anchor = Utils.popupAnchorForPoint(
                            Quickshell,
                            inlineItem.mapToGlobal(inlineItem.width / 2, 0),
                            Root.Tray.activeScreen
                        )
                        if (mouse.button === Qt.LeftButton) {
                            if (inlineItem.modelData.onlyMenu)
                                Root.Tray.showMenu(inlineItem.modelData, anchor.screen, anchor.x)
                            else
                                inlineItem.modelData.activate()
                        } else if (mouse.button === Qt.RightButton) {
                            Root.Tray.showMenu(inlineItem.modelData, anchor.screen, anchor.x)
                        }
                    }
                }

                opacity: iconMouse.containsMouse ? 1.0 : 0.7

                Behavior on opacity {
                    OpacityAnimator { duration: Root.Theme.durationFast; easing.type: Easing.OutCubic }
                }
            }
        }

        // Overflow icon — opens TrayPopup
        Item {
            width: 18
            height: 18
            visible: trayInline._hasOverflow

            Text {
                anchors.centerIn: parent
                text: "󰇙"
                font.pixelSize: 14
                font.family: Root.Theme.fontFamily
                color: overflowMouse.containsMouse ? Root.Theme.primary : Root.Theme.on.surface

                Behavior on color {
                    ColorAnimation { duration: Root.Theme.durationFast }
                }
            }

            MouseArea {
                id: overflowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var anchor = Utils.popupAnchorForPoint(
                        Quickshell,
                        parent.mapToGlobal(parent.width / 2, 0),
                        Root.Tray.activeScreen
                    )
                    Root.Tray.updatePopupAnchor(anchor.screen, anchor.x)
                    Root.Tray.togglePopup()
                }
            }
        }
    }
}
